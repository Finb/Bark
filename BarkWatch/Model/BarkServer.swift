//
//  BarkServer.swift
//  Bark
//
//  Created by Jian Qin on 9/30/26.
//


import Foundation
import Observation

struct BarkServer: Codable, Identifiable, Equatable {
    let id: UUID
    let address: URL
    var deviceKey = ""

    init(address: String) throws {
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var components = URLComponents(string: trimmedAddress),
              let scheme = components.scheme?.lowercased(), ["http", "https"].contains(scheme),
              let host = components.host, !host.isEmpty,
              components.user == nil, components.password == nil,
              components.query == nil, components.fragment == nil else {
            throw BarkServerError("Enter a server address beginning with https:// or http://, without a key or query.")
        }
        components.scheme = scheme
        components.host = host.lowercased()
        while components.path.hasSuffix("/") { components.path.removeLast() }
        guard let url = components.url else { throw BarkServerError("Invalid server address.") }
        id = UUID()
        self.address = url
    }

    private enum CodingKeys: String, CodingKey {
        case id, address
        case deviceKey = "key"
    }

    var pushURL: URL { address.appendingPathComponent(deviceKey) }

    func makeRegistrationRequest(deviceToken: String) throws -> URLRequest {
        guard var components = URLComponents(url: address.appendingPathComponent("register"), resolvingAgainstBaseURL: false) else {
            throw BarkServerError("Invalid server address.")
        }
        components.queryItems = [URLQueryItem(name: "devicetoken", value: deviceToken), URLQueryItem(name: "key", value: deviceKey)]
        // A literal plus is interpreted as a space by form-style query parsers.
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        guard let registrationURL = components.url else { throw BarkServerError("Invalid registration address.") }
        return URLRequest(url: registrationURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
    }

    func makeTestPushRequest(sound: String = "default", critical: Bool = false, volume: Int = 5, encryption: CryptoSettingFields? = nil) throws -> URLRequest {
        var request = URLRequest(url: address.appendingPathComponent("push"), timeoutInterval: 20)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Exercise grouping, alert level, Markdown, links, images, and the notification icon.
        var payload = [
            "title": encryption == nil ? "Bark Watch test" : "Bark Watch encrypted test",
            "subtitle": "Feature check",
            "body": "sent through your Bark server.",
            "markdown": "sent through your **Bark server**.\n\n- *Markdown* ~~`code`~~ \n\n[Bark](https://bark.day.app)",
            "group": "Bark Watch test",
            "url": "https://github.com/sebersta",
            "image": "https://day.app/assets/images/avatar.jpg",
            "icon": "https://day.app/assets/images/avatar.jpg",
            "sound": sound,
            "level": critical ? "critical" : "active", "volume": String(min(10, max(0, volume)))
        ]
        if let encryption { payload = try WatchEncryption.encrypt(payload, fields: encryption) }
        payload["device_key"] = deviceKey
        // Kept outside the ciphertext so the server can use it as the collapse identifier;
        // repeated tests replace each other instead of piling up.
        payload["id"] = "bark-watch-test"
        request.httpBody = try JSONEncoder().encode(payload)
        return request
    }
}

struct BarkServerError: LocalizedError {
    let errorDescription: String?
    init(_ message: String) { errorDescription = message }
}

struct BarkResponse: Decodable {
    struct RegistrationData: Decodable { let key: String? }
    let code: Int
    let message: String?
    let data: RegistrationData?

    static func decode(_ data: Data, response: URLResponse) throws -> Self {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BarkServerError("The server returned an invalid response.")
        }
        let decodedResponse = try? JSONDecoder().decode(Self.self, from: data)
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw BarkServerError(decodedResponse?.message ?? "Server request failed (\(httpResponse.statusCode)).")
        }
        guard let decodedResponse else { throw BarkServerError("The server did not return a Bark response.") }
        guard decodedResponse.code == 200 else {
            throw BarkServerError(decodedResponse.message ?? "Bark request failed (\(decodedResponse.code)).")
        }
        return decodedResponse
    }
}

@Observable
@MainActor
final class BarkServers {
    private(set) var servers: [BarkServer] = []
    private(set) var statusMessages: [UUID: String] = [:]
    private(set) var errorMessages: [UUID: String] = [:]
    private(set) var busyServerIDs: Set<UUID> = []
    private(set) var storageError: String?
    private(set) var deviceToken: String?
    private let userDefaults: UserDefaults
    private let sendRequest: (URLRequest) async throws -> (Data, URLResponse)

    init(
        defaults: UserDefaults = .standard,
        send: @escaping (URLRequest) async throws -> (Data, URLResponse) = { try await URLSession.shared.data(for: $0) }
    ) {
        self.userDefaults = defaults
        self.sendRequest = send
        if let data = defaults.data(forKey: "barkWatchServers") {
            do { servers = try JSONDecoder().decode([BarkServer].self, from: data) }
            catch { storageError = "Saved servers could not be loaded: \(error.localizedDescription)" }
        }
    }

    @discardableResult
    func add(address: String) throws -> UUID {
        if let storageError { throw BarkServerError(storageError) }
        let server = try BarkServer(address: address)
        guard !servers.contains(where: { $0.address == server.address }) else {
            throw BarkServerError("This server is already saved.")
        }
        servers.append(server)
        save()
        return server.id
    }

    func remove(serverID: UUID) {
        servers.removeAll { $0.id == serverID }
        statusMessages[serverID] = nil
        errorMessages[serverID] = nil
        save()
    }

    func registerAll(deviceToken: String) async {
        self.deviceToken = deviceToken
        for serverID in servers.map(\.id) { await register(serverID: serverID) }
    }

    func register(serverID: UUID) async {
        guard !busyServerIDs.contains(serverID) else { return }
        guard deviceToken != nil else {
            statusMessages[serverID] = "Enable notifications to register this watch."
            return
        }
        busyServerIDs.insert(serverID)
        defer { busyServerIDs.remove(serverID) }
        // If Apple rotates the token during a request, keep the returned key and update it again.
        while let tokenToRegister = deviceToken,
              let server = servers.first(where: { $0.id == serverID }) {
            statusMessages[serverID] = "Registering key…"
            errorMessages[serverID] = nil
            do {
                let (data, response) = try await sendRequest(server.makeRegistrationRequest(deviceToken: tokenToRegister))
                let decodedResponse = try BarkResponse.decode(data, response: response)
                guard let registeredKey = decodedResponse.data?.key, !registeredKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw BarkServerError("The server did not return a device key.")
                }
                guard let index = servers.firstIndex(where: { $0.id == serverID }) else { return }
                servers[index].deviceKey = registeredKey
                save()
                statusMessages[serverID] = "Key registered"
                #if DEBUG
                print("Bark watch server: \(server.address.absoluteString)")
                print("Bark watch device key: \(registeredKey)")
                #endif
            } catch {
                guard servers.contains(where: { $0.id == serverID }) else { return }
                statusMessages[serverID] = nil
                errorMessages[serverID] = error.localizedDescription
            }
            if tokenToRegister == deviceToken { return }
        }
    }

    func sendTestPush(serverID: UUID, sound: String = "default", critical: Bool = false, volume: Int = 5, encrypted: Bool = false) async {
        guard !busyServerIDs.contains(serverID), let server = servers.first(where: { $0.id == serverID }), !server.deviceKey.isEmpty else { return }
        busyServerIDs.insert(serverID)
        errorMessages[serverID] = nil
        statusMessages[serverID] = "Sending…"
        let tokenBeforeSending = deviceToken
        do {
            let fields = encrypted ? try WatchCryptoStore.load() : nil
            if encrypted && fields == nil { throw WatchCryptoError("Save an encryption key first.") }
            let (data, response) = try await sendRequest(server.makeTestPushRequest(sound: sound, critical: critical, volume: volume, encryption: fields))
            _ = try BarkResponse.decode(data, response: response)
            if servers.contains(where: { $0.id == serverID }) {
                statusMessages[serverID] = "Server accepted the test. Watch for the notification."
            }
        } catch {
            if servers.contains(where: { $0.id == serverID }) {
                statusMessages[serverID] = nil
                errorMessages[serverID] = error.localizedDescription
            }
        }
        busyServerIDs.remove(serverID)
        if tokenBeforeSending != deviceToken { await register(serverID: serverID) }
    }

    private func save() {
        do { userDefaults.set(try JSONEncoder().encode(servers), forKey: "barkWatchServers") }
        catch { storageError = "Servers could not be saved: \(error.localizedDescription)" }
    }
}
