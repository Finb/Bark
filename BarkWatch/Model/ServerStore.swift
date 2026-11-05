import Foundation
import Observation
import RxSwift

@MainActor
@Observable
final class ServerStore {
    enum TestResult {
        case sent
        case failed(String)
    }

    private let manager = ServerManager.shared
    private let disposeBag = DisposeBag()

    private(set) var servers: [Server] = []
    private(set) var currentServer: Server?
    private(set) var isSending = false
    private(set) var testResult: TestResult?
    private(set) var isSyncingServers = false
    var syncServersFailed = false

    init() {
        reload()
        manager.currentServerUpdateRelay
            .subscribe(onNext: { [weak self] _ in
                Task { @MainActor in self?.reload() }
            })
            .disposed(by: disposeBag)
    }

    func reload() {
        servers = manager.servers
        currentServer = manager.currentServer
    }

    func sync(deviceToken: String) {
        manager.syncAllServers(deviceToken: deviceToken)
    }

    func syncServers(deviceToken: String?) async {
        guard !isSyncingServers else { return }
        isSyncingServers = true
        defer { isSyncingServers = false }

        do {
            guard let data = try await PhoneSyncManager.shared.requestData(for: .serverList),
                  let incoming = try? JSONDecoder().decode([String].self, from: data)
            else {
                syncServersFailed = true
                return
            }
            importServers(incoming, deviceToken: deviceToken)
        } catch {
            syncServersFailed = true
        }
    }

    func importServers(_ incoming: [String], deviceToken: String?) {
        guard !incoming.isEmpty else { return }

        let existing = manager.servers
        var knownAddresses = Set(existing.map(\.cleanAddress))
        for address in incoming where !knownAddresses.contains(address) {
            knownAddresses.insert(address)
            manager.addServer(server: Server(address: address, key: ""))
        }

        reload()

        if let deviceToken {
            manager.syncAllServers(deviceToken: deviceToken)
        }
    }

    func setCurrent(_ server: Server) {
        manager.setCurrentServer(serverId: server.id)
        reload()
    }

    @discardableResult
    func addServer(address: String, deviceToken: String?) -> Bool {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = url.host,
              !host.isEmpty
        else {
            return false
        }

        let cleanAddress = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        let server = Server(address: cleanAddress, key: "")
        manager.addServer(server: server)
        manager.setCurrentServer(serverId: server.id)
        reload()

        if let deviceToken {
            manager.syncAllServers(deviceToken: deviceToken)
        }
        return true
    }

    func remove(_ server: Server, deviceToken: String?) {
        guard manager.servers.count > 1 else { return }
        manager.removeServer(server: server)
        reload()

        if let deviceToken {
            manager.syncAllServers(deviceToken: deviceToken)
        }
    }

    func resetTestResult() {
        testResult = nil
    }

    func sendTest(server: Server) async {
        guard !server.key.isEmpty else {
            testResult = .failed("deviceNotRegistered".localized)
            return
        }
        guard let baseURL = URL(string: server.cleanAddress) else {
            testResult = .failed("InvalidServer".localized)
            return
        }

        var request = URLRequest(url: baseURL.appendingPathComponent("push"))
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "device_key": server.key,
            "title": "title",
            "body": "body",
            "group": "example"
        ])

        isSending = true
        testResult = nil
        defer { isSending = false }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            let code = json?["code"] as? Int

            if (200..<300).contains(statusCode), code == 200 {
                testResult = .sent
            } else {
                let message = json?["message"] as? String ?? "HTTP \(statusCode)"
                testResult = .failed("testPushFailed".localized(with: message))
            }
        } catch {
            testResult = .failed("testPushFailed".localized(with: error.localizedDescription))
        }
    }
}
