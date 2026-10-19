//
//  NotificationTests.swift
//  Bark
//
//  Created by Jian Qin on 9/30/26.
//

import Testing
import Intents
import UserNotifications
import SwiftUI
import UIKit
import WatchKit
@testable import BarkWatch

@MainActor
@Test func remoteDeletionRemovesOnlyMatchingMessagesAndHandlesFailures() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let archive = WatchArchive(directory: directory)
    let delegate = NotificationDelegate()
    let content = UNMutableNotificationContent()
    let keptID = "keep-\(UUID())"
    let deletedID = "delete-\(UUID())"
    content.title = "Keep"
    content.userInfo = ["id": keptID]
    try archive.save(#require(WatchArchivedMessage(content: content, identifier: keptID)))
    content.title = "Delete"
    content.userInfo = ["id": deletedID]
    try archive.save(#require(WatchArchivedMessage(content: content, identifier: deletedID, date: .now.addingTimeInterval(1))))
    delegate.state.receive(WatchMessage(content: content))
    let link = try #require(URL(string: "https://example.com/deleted"))
    delegate.state.requestedNotificationURL = link
    delegate.state.pendingBrowserURL = link

    for info: [AnyHashable: Any] in [[:], ["id": deletedID], ["delete": "0", "id": deletedID], ["delete": "1"], ["delete": "1", "id": ""], ["delete": "1", "id": [deletedID]]] {
        #expect(delegate.handleRemoteNotification(info, archive: archive) == .noData)
    }
    #expect(try archive.messages().count == 2)
    #expect(delegate.state.lastMessage?.identifier == deletedID)
    #expect(delegate.handleRemoteNotification(["delete": "1", "id": "unknown"], archive: archive) == .newData)
    #expect(delegate.state.lastMessage?.identifier == deletedID)
    #expect(delegate.state.pendingBrowserURL == link)

    #expect(delegate.handleRemoteNotification(["delete": 1, "id": deletedID], archive: archive) == .newData)
    #expect(try WatchArchive(directory: directory).messages().map(\.id) == [keptID])
    #expect(try archive.latest(group: nil)?.title == "Keep")
    #expect(delegate.state.lastMessage == nil)
    #expect(delegate.state.requestedNotificationURL == nil)
    #expect(delegate.state.pendingBrowserURL == nil)
    #expect(delegate.handleRemoteNotification(["delete": "1", "id": deletedID], archive: archive) == .newData)
    #expect(try archive.messages().map(\.id) == [keptID])

    content.userInfo = ["delete": "1", "id": deletedID]
    #expect(WatchArchivedMessage(content: content, identifier: deletedID) == nil)
    let file = directory.appendingPathComponent("recent_messages.json")
    let corruptData = Data("invalid archive".utf8)
    try corruptData.write(to: file)
    #expect(delegate.handleRemoteNotification(["delete": "1", "id": deletedID], archive: archive) == .failed)
    #expect(try Data(contentsOf: file) == corruptData)

    var results: [WKBackgroundFetchResult] = []
    delegate.didReceiveRemoteNotification(["delete": "1"]) { results.append($0) }
    #expect(results == [.noData])
}

@Test func notificationIconIntentValidatesImageAndPreservesSender() throws {
    let content = UNMutableNotificationContent()
    content.title = "Build monitor"
    content.body = "Build completed"
    let png = try #require(Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII="))
    #expect(WatchNotification.iconIntent(for: content, imageData: png) == nil)
    content.userInfo = ["icon": "file:///private/icon.png"]
    #expect(WatchNotification.iconIntent(for: content, imageData: png) == nil)
    content.userInfo = ["icon": "https://example.com/icon.png"]
    #expect(WatchNotification.iconIntent(for: content, imageData: Data("not an image".utf8)) == nil)
    #expect(WatchNotification.iconIntent(for: content, imageData: Data(repeating: 0, count: 5 * 1024 * 1024 + 1)) == nil)
    let intent = try #require(WatchNotification.iconIntent(for: content, imageData: png))
    #expect(intent.sender?.displayName == content.title)
    #expect(intent.sender?.image != nil)
    #expect(intent.content == content.body)
    #expect(intent.conversationIdentifier == "https://example.com/icon.png")
    content.title = ""
    content.threadIdentifier = "Builds"
    let untitled = try #require(WatchNotification.iconIntent(for: content, imageData: png))
    #expect(untitled.sender?.displayName == "Bark")
    #expect(untitled.conversationIdentifier == "Builds")
}

@Test func watchNotificationOptionsAndFallbacks() throws {
    let content = UNMutableNotificationContent()
    content.body = "Fallback"
    content.badge = 9
    content.userInfo = ["markdown": "**Bold** and `code`\nSecond line", "group": "Training", "level": "timeSensitive", "aps": ["sound": "minuet.caf"]]
    WatchNotification.prepare(content)
    #expect(content.body == "Bold and code Second line")
    #expect(content.threadIdentifier == "Training")
    #expect(content.interruptionLevel == .timeSensitive)
    #expect(content.sound != nil)
    #expect(content.badge == nil)
    #expect(WatchNotification.presentationOptions(for: content).contains(.sound))

    content.userInfo = ["level": "passive", "aps": ["sound": "default"]]
    WatchNotification.applyLevel(content)
    #expect(content.interruptionLevel == .passive)
    #expect(content.sound == nil)
    #expect(WatchNotification.presentationOptions(for: content) == [.list])
    content.userInfo = ["level": "critical", "aps": ["sound": "default"]]
    WatchNotification.applyLevel(content)
    #expect(content.interruptionLevel == .active)
    #expect(WatchMessage(content: content).usedCriticalAlertFallback)
    WatchNotification.applyLevel(content, criticalAlertsEnabled: true)
    #expect(content.interruptionLevel == .critical)
    #expect(content.sound != nil)
    #expect(!WatchMessage(content: content).usedCriticalAlertFallback)
    #expect(WatchNotification.presentationOptions(for: content).contains(.sound))
    #expect(WatchNotification.criticalSoundVolume([:]) == 0.5)
    #expect(WatchNotification.criticalSoundVolume(["volume": "3"]) == 0.3)
    #expect(WatchNotification.criticalSoundVolume(["volume": 20]) == 1)
    #expect(WatchNotification.criticalSoundVolume(["volume": -3]) == 0)
    #expect(WatchNotification.criticalSoundVolume(["volume": "nan"]) == 0.5)
    #expect(WatchNotification.criticalSoundVolume(["volume": "inf"]) == 0.5)
    content.userInfo = ["level": "critical", "aps": ["sound": "silent"]]
    WatchNotification.applyLevel(content, criticalAlertsEnabled: true)
    #expect(content.interruptionLevel == .critical)
    #expect(content.sound == nil)
    content.userInfo = ["level": "active", "aps": ["sound": "silent"], "url": "https://example.com/watch", "image": "https://example.com/image.png", "id": "progress"]
    WatchNotification.applyLevel(content)
    #expect(content.sound == nil)
    #expect(!WatchNotification.presentationOptions(for: content).contains(.sound))
    let message = WatchMessage(content: content)
    #expect(message.url?.host == "example.com")
    #expect(message.image?.path == "/image.png")
    #expect(message.identifier == "progress")
    for address in ["javascript:alert(1)", "file:///private/data", "https://user:pass@example.com", "https://"] {
        #expect(WatchNotification.validatedWebURL(address) == nil)
    }
    #expect(WatchNotification.stringValue("badge", in: ["badge": 3]) == "3")
    content.userInfo = ["level": "active", "aps": ["sound": "system.caf"]]
    WatchNotification.applyLevel(content)
    #expect(content.sound != nil)
}

@Test(arguments: ["silent", "silent.caf", "SILENT.CAF"])
func silentSoundDisablesAlertSound(soundName: String) {
    for level in ["active", "timeSensitive", "critical"] {
        let content = UNMutableNotificationContent()
        content.sound = .default
        content.userInfo = ["level": level, "aps": ["sound": soundName]]
        WatchNotification.applyLevel(content, criticalAlertsEnabled: true)
        #expect(content.sound == nil)
        #expect(WatchNotification.presentationOptions(for: content) == [.banner, .list])
    }
}

@MainActor
@Test func notificationStatusReturnsWhenPermissionOrRegistrationIsLost() async throws {
    let suite = "BarkWatchTests.\(UUID())"
    let defaults = try #require(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    let state = NotificationState(servers: ServerManager(defaults: defaults))
    state.authorizationStatus = .authorized
    state.registrationState = .registered("test-token")
    #expect(state.needsNotificationSetup)
    let id = try state.servers.addServer(address: "https://bark.example")
    #expect(!state.needsNotificationSetup)
    state.authorizationStatus = .denied
    #expect(state.needsNotificationSetup)
    state.authorizationStatus = .provisional
    #expect(!state.needsNotificationSetup)
    for registrationState: NotificationState.PushRegistrationState in [.idle, .registering, .failed("Registration failed")] {
        state.registrationState = registrationState
        #expect(state.needsNotificationSetup)
    }
    state.authorizationStatus = .authorized
    state.registrationState = .registered("test-token")
    #expect(!state.needsNotificationSetup)
    await state.servers.removeServer(serverID: id)
    #expect(state.needsNotificationSetup)
}

@MainActor
@Test func latestNotificationReplacesPreviousContent() {
    let state = NotificationState()
    let content = UNMutableNotificationContent()
    content.title = "First"
    content.subtitle = "Bark subtitle"
    content.body = "First body"
    state.receive(WatchMessage(content: content))
    #expect(state.lastMessage?.title == "First")
    #expect(state.lastMessage?.subtitle == "Bark subtitle")
    #expect(state.lastMessage?.body == "First body")

    content.title = ""
    content.body = "Second body"
    state.receive(WatchMessage(content: content))
    #expect(state.lastMessage?.title == "")
    #expect(state.lastMessage?.body == "Second body")

    content.title = "Third"
    content.body = ""
    state.receive(WatchMessage(content: content))
    #expect(state.lastMessage?.title == "Third")
    #expect(state.lastMessage?.body == "")
}

@MainActor
@Test func barkRegistrationPersistenceRequestsAndFailures() async throws {
    let suite = "BarkWatchTests.\(UUID())"
    let defaults = try #require(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    let store = ServerManager(defaults: defaults, send: barkResponse)

    for address in ["", "example.com", "file:///tmp/server", "https://example.com?key=secret", "https://user:pass@example.com", "https://example.com/#fragment"] {
        #expect(throws: BarkServerError.self) { try store.addServer(address: address) }
    }
    let id = try store.addServer(address: "  https://BARK.EXAMPLE/proxy/  ")
    #expect(throws: BarkServerError.self) { try store.addServer(address: "https://bark.example/proxy") }
    #expect(try Server(address: "http://192.168.1.2:8080/").address.absoluteString == "http://192.168.1.2:8080")
    await store.register(serverID: id)
    #expect(store.servers.first?.key == "")
    await store.syncAllServers(deviceToken: "first-token")
    #expect(store.servers.first?.key == "watch-key")
    #expect(store.errorMessages[id] == nil)
    #expect(store.busyServerIDs.isEmpty)
    await store.syncAllServers(deviceToken: "rotated-token")
    #expect(store.servers.first?.key == "watch-key")

    var server = try #require(store.servers.first)
    let restored = ServerManager(defaults: defaults, send: barkResponse)
    #expect(restored.servers == store.servers)
    #expect(restored.deviceToken == nil)
    // Existing installations persist "key"; the Swift property rename must not change it.
    let legacyData = try JSONSerialization.data(withJSONObject: [
        "id": server.id.uuidString, "address": server.address.absoluteString, "key": server.key
    ])
    #expect(try JSONDecoder().decode(Server.self, from: legacyData) == server)
    let encodedServer = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(server)) as? [String: Any])
    #expect(encodedServer["key"] as? String == server.key)
    #expect(encodedServer["deviceKey"] == nil)
    server.key = "a+b&c=d"
    let request = try BarkApi.register(address: server.address, key: server.key, devicetoken: "token+with&symbols").asURLRequest()
    let requestURL = try #require(request.url)
    let components = try #require(URLComponents(url: requestURL, resolvingAgainstBaseURL: false))
    #expect(request.httpMethod == "GET")
    #expect(components.path == "/proxy/register")
    #expect(components.queryItems?.first(where: { $0.name == "key" })?.value == server.key)
    #expect(components.queryItems?.first(where: { $0.name == "devicetoken" })?.value == "token+with&symbols")
    #expect(components.percentEncodedQuery?.contains("%2B") == true)

    let push = try server.makeTestPushRequest()
    #expect(push.httpMethod == "POST")
    #expect(push.url?.path == "/proxy/push")
    #expect(push.value(forHTTPHeaderField: "Content-Type") == "application/json")
    let body = try JSONDecoder().decode([String: String].self, from: #require(push.httpBody))
    #expect(body["device_key"] == server.key)
    #expect(body["sound"] == "default")
    let criticalRequest = try server.makeTestPushRequest(sound: "default", critical: true, volume: 8)
    let criticalBody = try JSONDecoder().decode([String: String].self, from: #require(criticalRequest.httpBody))
    #expect(criticalBody["level"] == "critical")
    #expect(criticalBody["volume"] == "8")
    let silentRequest = try server.makeTestPushRequest(sound: "none")
    let silentBody = try JSONDecoder().decode([String: String].self, from: #require(silentRequest.httpBody))
    #expect(silentBody["sound"] == "none")
    await store.sendTestPush(serverID: id)
    #expect(store.statusMessages[id]?.contains("accepted") == true)
    #expect(store.errorMessages[id] == nil)

    for host in ["rejected.example", "missing-key.example", "malformed.example", "offline.example"] {
        let failedID = try store.addServer(address: "https://\(host)")
        await store.register(serverID: failedID)
        #expect(store.errorMessages[failedID] != nil)
        #expect(store.servers.first(where: { $0.id == failedID })?.key == "")
        #expect(!store.busyServerIDs.contains(failedID))
        await store.removeServer(serverID: failedID)
    }
    let response = try #require(HTTPURLResponse(url: server.address, statusCode: 503, httpVersion: nil, headerFields: nil))
    #expect(throws: BarkServerError.self) {
        try BarkResponse.decode(Data(#"{"code":200,"data":{"key":"must-not-save"}}"#.utf8), response: response)
    }
    await store.removeServer(serverID: id)
    #expect(ServerManager(defaults: defaults).servers.isEmpty)
}

@MainActor
@Test func registrationUsesRotatedTokenAndIgnoresRemovedServers() async throws {
    let suite = "BarkWatchTests.\(UUID())"
    let defaults = try #require(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    let (requestStarted, signalRequestStarted) = AsyncStream<Void>.makeStream()
    let (resumeRequest, signalResumeRequest) = AsyncStream<Void>.makeStream()
    defer {
        signalRequestStarted.finish()
        signalResumeRequest.finish()
    }
    var requestCount = 0
    var unregisteredKeys: [String] = []
    let store = ServerManager(defaults: defaults) { request in
        let query = request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems } ?? []
        if query.contains(URLQueryItem(name: "devicetoken", value: "deleted")) {
            unregisteredKeys.append(query.first { $0.name == "key" }?.value ?? "")
            return try await barkResponse(for: request)
        }
        requestCount += 1
        signalRequestStarted.yield(())
        var iterator = resumeRequest.makeAsyncIterator()
        await iterator.next()
        return try await barkResponse(for: request)
    }
    let serverID = try store.addServer(address: "https://bark.example")
    var startedRequests = requestStarted.makeAsyncIterator()
    let registration = Task { await store.syncAllServers(deviceToken: "first-token") }
    await startedRequests.next()
    // A concurrent token refresh must not send a duplicate request while this one is busy.
    await store.syncAllServers(deviceToken: "rotated-token")
    #expect(requestCount == 1)
    signalResumeRequest.yield(())
    await startedRequests.next()
    signalResumeRequest.yield(())
    await registration.value
    #expect(requestCount == 2)
    #expect(store.servers.first?.key == "watch-key")
    #expect(store.errorMessages[serverID] == nil)
    #expect(store.busyServerIDs.isEmpty)

    let refresh = Task { await store.register(serverID: serverID) }
    await startedRequests.next()
    await store.removeServer(serverID: serverID)
    signalResumeRequest.yield(())
    await refresh.value
    // Removal invalidates the old key on the server, like the phone's server list does.
    #expect(unregisteredKeys == ["watch-key"])
    #expect(store.servers.isEmpty)
    #expect(store.statusMessages[serverID] == nil)
    #expect(store.errorMessages[serverID] == nil)
    #expect(store.busyServerIDs.isEmpty)
}

// Local response stub: no network requests are made by this check.
@MainActor
private func barkResponse(for request: URLRequest) async throws -> (Data, URLResponse) {
    let url = request.url!
    let body: String
    switch url.host {
    case "offline.example":
        throw URLError(.notConnectedToInternet)
    case "rejected.example": body = #"{"code":400,"message":"Registration rejected"}"#
    case "missing-key.example": body = #"{"code":200,"data":{"key":""}}"#
    case "malformed.example": body = "not a Bark response"
    default:
        if url.lastPathComponent == "register" {
            let query = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
            let key = query.first(where: { $0.name == "key" })?.value
            let token = query.first(where: { $0.name == "devicetoken" })?.value
            let valid = (token == "first-token" && key == "") || (token == "rotated-token" && key == "watch-key")
            body = valid ? #"{"code":200,"data":{"key":"watch-key"}}"# : #"{"code":400,"message":"Wrong registration parameters"}"#
        } else {
            body = #"{"code":200,"message":"success"}"#
        }
    }
    let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
    return (Data(body.utf8), response)
}

// Independent compatibility vectors generated with node:crypto, matching the phone scripts.
@Test func encryptedNotificationsMatchPhoneWireFormat() throws {
    let vectors: [(String, String, String)] = [
        ("AES128", "CBC", "ShFOkZwRwKcHQRzzwb9qvSGKwatwVEUWmbHv8ydX9kRfIgIyQEkrY0iLIZrg5Tc5GjxmVWTajM3CIDT9aAulkIU8Gb0VAKXhCp/0XRQxge5NL7rgGnYbZB1Bn5tO4TaEicZZC5baU7tpU4vdS+sXmMNSedjTTTCzbUWViAkMI6hzevILUUdHD7/9cEEabblnQ8xgAJVkbwdX87RZmmansxD6v0YDqWC4OS6oNyEBd/lrNaTIvM3Ct/fldEn3P0ErE5sDqkcwdhq3gJTwSKGEQw=="),
        ("AES128", "ECB", "fVv0lv/GjbI8zCO7Xw55gpf+d11SP+1YhGM5VGndAnldDVwAMEmq4OG04n2U7XFw5jU1kAJhxoRzt5YUBSPm0crgSJiqSPIAs/USAYTHcBqiDrgeP8iyCfnt41Ns/qRV2Z2OHsTYm5rpP9JZir6xZmi108u9awbCZIXRgrSidYH6/BtihWEweZsvDdW51DsNR4a6eZSMwEOh1PIXmk6gPydbJEuLAMQ809ZZVUeapufUAh82uDqgdRhlwMevnrmvN3Ii4GGpJMWRzZwn6hY+1A=="),
        ("AES128", "GCM", "nvAo/AfpHIdjEvFUlUymeX5wiMfIZKnmptDvCyc1PNhocjqzBJGTKfeeKDxAu3of/51mSCKis4WJEUfJW1EnoQsUZEeUuRm7Lg++o+DSl9oe1E+IhXG3wDBsgs/IBZxuQuf9qAHyzyXWpi8ypYTybAm9+Cetkw1Oal/z7ekBGZsU2OQ11mUvweFbHMG7oHrwnJYdtMX8hlghpZ9Oim3Y/hl0kOYNwh8JA7LsI2b9CBqwRjl9YvKkDWFdpQP1O9jHgcK1Lq3AI9IrjNzdxOu3mg=="),
        ("AES192", "CBC", "iCAbTlSF1BfjAynBOSFhJ3uunLg5F3gvSTQpHD60rMz9tw/GZxBCpjFkd36BC/cJcNvcO3oZdugYR0zLdkLbrKaB7En9d1q56toktbAat8t/RW2QCB2In4NsQt+zPaVwtZ3+LgTC68fX2TYHwLOg2le9uMhg4qcul9kU/AGuvWI4lgVqoq9bPtAIKwzqUhNUBrKW2FI2aFghutzcjJdZbLYLcJtWqbZiNEGfavsfJ5dnXT1qm+eklMBTuLVJmYmHX8p/sdNEaFqNRhDfZtHBBQ=="),
        ("AES192", "ECB", "kZvc1kLjCJAf+gTM6dTFbpQPt7jYa7MDtmk3UwbkvgFpUCtha9qonkYi21AT41PiKXXKsnLUdZ2TMlbqOg2clo4ahy1wQwE0OyqInRORwEdzULqA5yKVYSfmMw1QVw/K8QMK6vUsvLHcQLd1Lf6FNhYSEsiCaK29Y596CXxFhFEp/0Qjzd8/fk7Z/qKm1+2abIXNrVPT5oQZJadeuA4z2/EMzpiaq9dPnzbnbCPvBSME5B3NjNjyiOKwDDt2Jgt8DGdTta4MJQgKttDjLjGNMg=="),
        ("AES192", "GCM", "g46nzO6hDrMnqVOWf+NUQPbu2bGZHL8iB4JxNuovBwymWP3SC/MUQvWrHoiMX8tlPmZxhUiHdND1K+TBj84gOtxH8JADrS9dQyTX4zMel7nw/WyK4EpOUJ+YZzBwdV80ayrCrf0oU87Rw/SyJXxsx90fzFSKMJsGq0zwRPrF1HBdmqGn9YyB8YJ00rw4rlq33vR+bbG0kmWF3UoRqmmh5DXoxHo0ZoG6d4xGkVfVuP7yg80pAuahgZrrTR+Mew61EifzOzHTzHm/3ijTseXDPA=="),
        ("AES256", "CBC", "y8Jui/iMYIi7bZt/8vN1A5XdHtQcQosLm1Mc41003inCQLc7Q5Ku/s4+8wYQGGrpF1S3jllvyFwU3X2kxhwHB7Lc8AazTSTsLwM3o3/XThF0B/dlndsDpBdYfilSUa1B+3CeeYqwmSXOTc7QWgBOaFyQ4Ojn0H9sA2XtwRhqzjK8YrkopNdqsOdeBFPpkYt+gKaoRSszHEiNWALJivMoy3fPw5ylq2rQ4MgX7xLzEFBbwEHo/Sjv3RA86Xnw6NuCQTAh37FAGZebHylhcAbEBA=="),
        ("AES256", "ECB", "z3VG2WcSCSfWrqeHMig9VANuOsO6iGZOBa4t8QrplUXQd06B+YQ3/XhM9lxjsh/l1hd8RcfYe15etBwWypGvYskeWzphT4aXmzDea3ZXwBc6GDwp17IfxAfpZBBo6Gu0zKHUOLcy2iEO5byMfDTWMuabBOQGDag/TcQfvLegNQMMmuVsa7KxCg5AIZsdZzYsGpsA6chdck5sDEt7zj8ZSS+xYd2fO+2sQSvQhi7/WT+B/v8ICQVeMgGRI4WdSAkziqNiQf3o3wVNwyXGxpW4ng=="),
        ("AES256", "GCM", "Eu6d9p+pKPFZPrd/aeshTyhU3z9JH/XvPJIc76c+uoMYpMXeFHawwjgRsMNh/ve86jze3dc3AoL8020vw8nxZ/bR6qycM88RawpmC0YGgB2WnIURirMFbqM+BaIDhVhlw+aF243NaCKCvAfqFNRClSnUkzBOcF1Yk0HhNtRudyilcVtoWpoAx6cW7nybJ/TK4ptLiaelfyz32/q4yYh0WMLdVfJyz57txWRwOBXb5lncbHJr/7G8y1ONn6OFMIXybruLvEIa3l3UP2pnWRlnWg=="),
    ]
    for (algorithm, mode, ciphertext) in vectors {
        let key = String("0123456789abcdef0123456789abcdef".prefix(Algorithm(rawValue: algorithm)!.keyLength))
        let iv = mode == "GCM" ? "abcdefghijkl" : "abcdefghijklmnop"
        let fields = CryptoSettingFields(algorithm: algorithm, mode: mode,
            padding: mode == "GCM" ? "noPadding" : "pkcs7", key: key, iv: nil)
        let content = UNMutableNotificationContent()
        content.title = "Outer title must disappear"
        content.userInfo = ["ciphertext": ciphertext, "iv": iv, "url": "https://outer.invalid"]
        #expect(WatchEncryption.prepare(content) { fields })
        WatchNotification.prepare(content)
        #expect(content.title == "Encrypted 🚴")
        #expect(content.subtitle == "Bark compatibility")
        #expect(content.body == "café\nSecond line")
        #expect(content.sound != nil)
        #expect(content.interruptionLevel == .timeSensitive)
        #expect(content.threadIdentifier == "Private")
        #expect(content.userInfo["volume"] as? String == "3")
        #expect(content.userInfo["icon"] as? String == "https://example.com/icon.png")
        #expect(content.userInfo["ciphertext"] == nil)
        #expect(content.userInfo["url"] == nil)
        var fallback = fields
        fallback.iv = iv
        let storedIV = UNMutableNotificationContent()
        storedIV.userInfo = ["ciphertext": ciphertext]
        #expect(WatchEncryption.prepare(storedIV) { fallback })
        #expect(storedIV.body == content.body)
        let wrapped = String(ciphertext.prefix(40)) + "\n" + String(ciphertext.dropFirst(40))
        #expect(try WatchEncryption.decryptPayload(wrapped, fields: fallback)["title"] as? String == "Encrypted 🚴")
    }
}

@Test func watchEncryptionValidatesBytesAndSettings() throws {
    let fields = CryptoSettingFields(algorithm: "AES128", mode: "CBC", padding: "pkcs7",
        key: String(repeating: "é", count: 8), iv: String(repeating: "é", count: 8))
    let model = try AESCryptoModel(watchFields: fields)
    let ciphertext = try model.encrypt(text: #"{"BODY":"café","volume":3}"#)
    let payload = try WatchEncryption.decryptPayload(ciphertext, fields: fields)
    #expect(payload["body"] as? String == "café")
    #expect(payload["volume"] as? String == "3")
    #expect(try JSONDecoder().decode(CryptoSettingFields.self,
        from: JSONEncoder().encode(fields)) == fields)
    for invalid in [
        CryptoSettingFields(algorithm: "unknown", mode: "CBC", padding: "pkcs7", key: fields.key, iv: fields.iv),
        CryptoSettingFields(algorithm: "AES128", mode: "unknown", padding: "pkcs7", key: fields.key, iv: fields.iv),
        CryptoSettingFields(algorithm: "AES128", mode: "CBC", padding: "unknown", key: fields.key, iv: fields.iv),
        CryptoSettingFields(algorithm: "AES128", mode: "GCM", padding: "pkcs7", key: fields.key, iv: "abcdefghijkl"),
        CryptoSettingFields(algorithm: "AES128", mode: "CBC", padding: "pkcs7", key: fields.key, iv: String(repeating: "é", count: 16))
    ] {
        #expect(throws: WatchCryptoError.self) { try AESCryptoModel(watchFields: invalid) }
    }
}

@Test func encryptedNotificationFailuresDoNotExposeOuterPayload() throws {
    let fields = CryptoSettingFields(algorithm: "AES256", mode: "GCM", padding: "noPadding",
        key: "0123456789abcdef0123456789abcdef", iv: "abcdefghijkl")
    let model = try AESCryptoModel(watchFields: fields)
    let valid = try model.encrypt(text: #"{"body":"Private"}"#)
    var tampered = Array(try #require(Data(base64Encoded: valid)))
    tampered[tampered.count - 1] ^= 1
    for ciphertext in ["!not-base64!", Data(tampered).base64EncodedString(),
                       try model.encrypt(text: "not JSON"), try model.encrypt(text: "[]"),
                       try model.encrypt(text: #"{"body":"first","BODY":"second"}"#)] {
        let content = UNMutableNotificationContent()
        content.title = "Untrusted title"
        content.subtitle = "Untrusted subtitle"
        content.body = "Untrusted body"
        content.userInfo = ["ciphertext": ciphertext, "icon": "https://outer.invalid/icon.png"]
        #expect(!WatchEncryption.prepare(content) { fields })
        #expect(content.title == "Bark")
        #expect(content.subtitle.isEmpty)
        #expect(content.body == "Decryption Failed")
        #expect(content.userInfo["icon"] == nil)
    }
    let content = UNMutableNotificationContent()
    content.userInfo = ["ciphertext": valid]
    #expect(!WatchEncryption.prepare(content) { nil })
    content.userInfo = ["ciphertext": valid, "iv": "short"]
    #expect(!WatchEncryption.prepare(content) { fields })
    let wrong = CryptoSettingFields(algorithm: "AES256", mode: "GCM", padding: "noPadding",
        key: "fedcba9876543210fedcba9876543210", iv: fields.iv)
    content.userInfo = ["ciphertext": valid]
    #expect(!WatchEncryption.prepare(content) { wrong })
    let plain = UNMutableNotificationContent()
    plain.body = "Plain notifications still work"
    #expect(WatchEncryption.prepare(plain) { throw WatchCryptoError("Must not read Keychain") })
    #expect(plain.body == "Plain notifications still work")
    #expect(throws: WatchCryptoError.self) {
        try AESCryptoModel(watchFields: CryptoSettingFields(algorithm: "AES128", mode: "CBC",
            padding: "pkcs7", key: String(repeating: "é", count: 16), iv: "abcdefghijklmnop"))
    }
}

@MainActor
@Test func encryptedTestRequestContainsNoPlaintextAndUsesFreshVectors() throws {
    var server = try Server(address: "https://bark.example")
    server.key = "watch-key"
    for mode in ["CBC", "ECB", "GCM"] {
        let fields = CryptoSettingFields(algorithm: "AES256", mode: mode,
            padding: mode == "GCM" ? "noPadding" : "pkcs7", key: "0123456789abcdef0123456789abcdef", iv: nil)
        let request = try server.makeTestPushRequest(sound: "silent", encryption: fields)
        let payload = try JSONDecoder().decode([String: String].self, from: #require(request.httpBody))
        #expect(payload["device_key"] == server.key)
        #expect(payload["title"] == nil && payload["body"] == nil && payload["sound"] == nil)
        #expect(payload["key"] == nil)
        let content = UNMutableNotificationContent()
        content.userInfo = payload
        #expect(WatchEncryption.prepare(content) { fields })
        #expect(content.title == "Bark Watch encrypted test")
        WatchNotification.prepare(content)
        #expect(content.sound == nil)
        let again = try WatchEncryption.encrypt(["body": "test"], fields: fields)
        if mode == "ECB" { #expect(payload["iv"] == nil) }
        else { #expect(payload["iv"] != again["iv"]) }
    }
}

@Test func encryptionSettingsPersistWithoutDestroyingSavedKeysOnError() throws {
    let account = "test-" + UUID().uuidString
    defer { try? WatchCryptoStore.save(nil, account: account) }
    let fields = CryptoSettingFields(algorithm: "AES256", mode: "GCM", padding: "noPadding",
        key: "0123456789abcdef0123456789abcdef", iv: nil)
    #expect(try WatchCryptoStore.load(account: account) == nil)
    try WatchCryptoStore.save(fields, account: account)
    #expect(try WatchCryptoStore.load(account: account) == fields)
    let bad = CryptoSettingFields(algorithm: "AES256", mode: "GCM", padding: "noPadding", key: "short", iv: nil)
    #expect(throws: WatchCryptoError.self) { try WatchCryptoStore.save(bad, account: account) }
    #expect(try WatchCryptoStore.load(account: account) == fields)
    var updated = fields
    updated.iv = "abcdefghijkl"
    try WatchCryptoStore.save(updated, account: account)
    #expect(try WatchCryptoStore.load(account: account) == updated)
    try WatchCryptoStore.save(nil, account: account)
    #expect(try WatchCryptoStore.load(account: account) == nil)
}

@Test func archivePersistsFiltersReplacesAndExpires() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let archive = WatchArchive(directory: directory)
    let now = Date()
    let content = UNMutableNotificationContent()
    content.title = "First\nTitle"
    content.body = "Body line one\nBody line two"
    content.userInfo = ["group": "Training", "id": "replace-me"]
    let first = try #require(WatchArchivedMessage(content: content, identifier: "request-1", date: now))
    try archive.save(first)
    #expect(try WatchArchive(directory: directory).latest(group: "Training")?.title == "First Title")
    #expect(try archive.latest(group: "Training")?.body == content.body)
    #expect(try archive.latest(group: "Other") == nil)
    content.title = "Updated"
    try archive.save(#require(WatchArchivedMessage(content: content, identifier: "request-2", date: now.addingTimeInterval(1))))
    #expect(try archive.messages().count == 1)
    content.userInfo = ["group": "Other", "ttl": "60"]
    try archive.save(#require(WatchArchivedMessage(content: content, identifier: "request-3", date: now.addingTimeInterval(2))))
    #expect(try archive.latest(group: nil)?.group == "Other")
    #expect(try archive.latest(group: "Training")?.title == "Updated")
    #expect(try archive.latest(group: nil, at: now.addingTimeInterval(63))?.group == "Training")
    for info: [String: Any] in [["isarchive": "0"], ["isarchive": 0], ["ttl": "0"], ["ttl": "-1"], ["ttl": "nan"]] {
        content.userInfo = info
        #expect(WatchArchivedMessage(content: content, identifier: "skip") == nil)
    }
    for index in 0..<110 {
        content.userInfo = ["group": "Bulk"]
        try archive.save(#require(WatchArchivedMessage(content: content, identifier: "bulk-\(index)", date: now.addingTimeInterval(Double(index + 3)))))
    }
    #expect(try archive.messages().count == 100)
    #expect(try archive.latest(group: nil)?.id == "bulk-109")
}

@MainActor
@Test func lastMessageIsRestoredFromArchive() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let archive = WatchArchive(directory: directory)
    let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
    #expect(NotificationState(servers: ServerManager(defaults: defaults), archive: archive).lastMessage == nil)

    let content = UNMutableNotificationContent()
    content.title = "Older"
    content.subtitle = "Subtitle"
    content.userInfo = ["group": "Ops", "level": "timeSensitive", "markdown": "**Bold**",
                        "url": "https://day.app", "image": "file:///private/image.png"]
    WatchNotification.prepare(content)
    try archive.save(#require(WatchArchivedMessage(content: content, identifier: "older", date: .now)))
    content.title = "Newer"
    try archive.save(#require(WatchArchivedMessage(content: content, identifier: "newer", date: .now.addingTimeInterval(1))))

    let state = NotificationState(servers: ServerManager(defaults: defaults), archive: archive)
    let restored = try #require(state.lastMessage)
    #expect(restored.title == "Newer")
    #expect(restored.subtitle == "Subtitle")
    #expect(restored.body == "Bold")
    #expect(restored.markdown == "**Bold**")
    #expect(restored.group == "Ops")
    #expect(restored.level == .timeSensitive)
    #expect(restored.url == URL(string: "https://day.app"))
    #expect(restored.image == nil)
}

@MainActor
@Test func markdownUsesPhoneParserForFormattingAndNotificationFallback() throws {
    let source = """
    # Heading
    **Bold** and *italic*, ~~removed~~, `code` and [link](https://example.com).
    Soft break.  
    Hard break.

    > A quotation.

    3. Third
    4. Fourth
       - Nested

    - [x] Done
    - [ ] Pending

    ```swift
    let distance = 42

    print(distance)
    ```

    ```
    Separate block
    ```

    ![Photo](https://example.com/photo.png)
    """
    let text = WatchMarkdownParser.parse(source, configuration: .init(baseFont: .systemFont(ofSize: 14)))
    func attributes(_ value: String) throws -> [NSAttributedString.Key: Any] {
        let range = (text.string as NSString).range(of: value)
        try #require(range.location != NSNotFound)
        return text.attributes(at: range.location, effectiveRange: nil)
    }
    #expect((try attributes("Heading")[.font] as? UIFont)?.pointSize == 20)
    #expect((try attributes("Bold")[.font] as? UIFont)?.fontDescriptor.symbolicTraits.contains(.traitBold) == true)
    #expect((try attributes("italic")[.font] as? UIFont)?.fontDescriptor.symbolicTraits.contains(.traitItalic) == true)
    #expect(try attributes("removed")[.strikethroughStyle] as? Int == NSUnderlineStyle.single.rawValue)
    #expect((try attributes("code")[.font] as? UIFont)?.fontDescriptor.symbolicTraits.contains(.traitMonoSpace) == true)
    #expect(try attributes("link")[.link] as? String == "https://example.com")
    #expect(try attributes("[Photo]")[.link] as? String == "https://example.com/photo.png")
    #expect((try attributes("A quotation")[.paragraphStyle] as? NSParagraphStyle)?.headIndent == 10)
    #expect(text.string.contains("3. Third") && text.string.contains("4. Fourth"))
    #expect(text.string.contains("☑ Done") && text.string.contains("☐ Pending"))
    #expect(text.string.contains("Soft break.\nHard break."))

    let paragraphs = WatchMarkdownParagraph.paragraphs(from: text)
    let nested = try #require(paragraphs.first { String($0.text.characters) == "Nested" })
    #expect(nested.indent == 20 && nested.markerWidth == 20)
    let code = paragraphs.filter(\.isCode)
    #expect(code.count == 2)
    #expect(String(code.first!.text.characters) == "let distance = 42\n\nprint(distance)")
    #expect(String(code.last!.text.characters) == "Separate block")
    let continued = WatchMarkdownParagraph.paragraphs(from: WatchMarkdownParser.parse("- First  \n  Continuation words"))
    let continuation = try #require(continued.last)
    #expect(String(continuation.text.characters) == "Continuation words")
    #expect(continuation.marker == nil && continuation.indent == 20)
    let blankCode = WatchMarkdownParagraph.paragraphs(from: WatchMarkdownParser.parse("```\n\nline\n\n```"))
    #expect(blankCode.count == 1 && blankCode.first?.isCode == true)
    #expect(String(blankCode[0].text.characters) == "\nline\n")
    let orderedTasks = WatchMarkdownParagraph.paragraphs(from: WatchMarkdownParser.parse("1. [x] Done\n2. [ ] Pending"))
    #expect(orderedTasks.map { $0.marker.map { String($0.characters) } } == ["1. ☑ ", "2. ☐ "])
    #expect(orderedTasks.map { String($0.text.characters) } == ["Done", "Pending"])
    let nestedCode = WatchMarkdownParagraph.paragraphs(from: WatchMarkdownParser.parse("- Code\n\n  ```\n  1. Literal code\n  ```"))
    let literalCode = try #require(nestedCode.first { $0.isCode })
    #expect(literalCode.marker == nil && String(literalCode.text.characters) == "1. Literal code")
    #expect(WatchMarkdownParagraph.paragraphs(from: WatchMarkdownParser.parse("`inline code`")).allSatisfy { !$0.isCode })
    let unsafe = WatchMarkdownParagraph.paragraphs(from: WatchMarkdownParser.parse("[bad](javascript:alert) [good](https://example.com)"))
    let links = unsafe.flatMap { $0.text.runs.compactMap { $0.link } }
    #expect(links == [URL(string: "https://example.com")!])
    #expect(WatchMarkdownParagraph.paragraphs(from: WatchMarkdownParser.parse("")).isEmpty)
    #expect(!WatchMarkdownParser.parse("**unfinished").string.isEmpty)

    let content = UNMutableNotificationContent()
    content.title = "Markdown test"
    content.subtitle = "Phone-compatible formatting"
    content.userInfo = ["markdown": source, "level": "timeSensitive", "aps": ["alert": ["body": "fallback"], "sound": "silent"]]
    WatchNotification.prepare(content)
    #expect(content.categoryIdentifier == WatchNotification.markdownCategoryIdentifier)
    #expect(content.body == WatchNotification.markdownSummary(source))
    #expect(content.interruptionLevel == .timeSensitive && content.sound == nil)
    let alert = (content.userInfo["aps"] as? [String: Any])?["alert"] as? [String: Any]
    #expect(alert?["body"] as? String == content.body)
    #expect(WatchMessage(content: content).markdown == source)

    let fields = CryptoSettingFields(algorithm: "AES256", mode: "GCM", padding: "noPadding",
        key: "0123456789abcdef0123456789abcdef", iv: nil)
    let encrypted = UNMutableNotificationContent()
    encrypted.userInfo = try WatchEncryption.encrypt(["markdown": source], fields: fields)
    #expect(WatchEncryption.prepare(encrypted) { fields })
    WatchNotification.prepare(encrypted)
    #expect(encrypted.body == content.body)
    #expect(encrypted.categoryIdentifier == WatchNotification.markdownCategoryIdentifier)
    #expect(encrypted.userInfo["ciphertext"] == nil)

    let plain = UNMutableNotificationContent()
    plain.body = "Plain text"
    plain.categoryIdentifier = "ExistingCategory"
    WatchNotification.prepare(plain)
    #expect(plain.body == "Plain text" && plain.categoryIdentifier == "ExistingCategory")

    var standardHeight: CGFloat = 0
    for size in [DynamicTypeSize.large, .accessibility3] {
        let renderer = ImageRenderer(content: WatchMarkdownView(source: source)
            .padding(12).frame(width: 184).background(.black)
            .environment(\.colorScheme, .dark).environment(\.dynamicTypeSize, size))
        renderer.scale = 2
        let image = try #require(renderer.uiImage)
        #expect(image.size.width == 184 && image.size.height > 200)
        if size == .large { standardHeight = image.size.height }
        else { #expect(image.size.height > standardHeight) }
        try #require(image.pngData()).write(to: FileManager.default.temporaryDirectory
            .appendingPathComponent("markdown-\(size).png"))
    }
}
