import Foundation
import WidgetKit
import Darwin
import UserNotifications

// Shares the phone widget's bounded snapshot approach without its database dependency.
nonisolated struct WatchArchivedMessage: Codable, Equatable, Sendable {
    let id: String
    let title: String
    let body: String
    let group: String
    let date: Date
    let expires: Date?
    // Shown by the app's Last message page. Optional so archives written
    // before these fields existed still decode.
    let subtitle: String?
    let markdown: String?
    let level: String?
    let url: String?
    let image: String?
    let usedCriticalAlertFallback: Bool?

    /// Expects content already prepared by `WatchNotification.prepare`, so the
    /// body, group, and interruption level match what was delivered.
    init?(content: UNNotificationContent, identifier: String, date: Date = .now) {
        let info = content.userInfo
        func text(_ key: String) -> String? {
            (info[key] as? String) ?? (info[key] as? NSNumber)?.stringValue
        }
        guard text("isarchive").map({ $0 == "1" }) ?? true,
              text("delete") != "1",
              info["ciphertext"] == nil else { return nil }
        let ttl = text("ttl").flatMap(TimeInterval.init)
        if let ttl, !ttl.isFinite || ttl <= 0 { return nil }
        let customID = text("id") ?? ""
        id = customID.isEmpty ? identifier : customID
        title = content.title.components(separatedBy: .newlines).joined(separator: " ")
        body = content.body
        group = text("group") ?? content.threadIdentifier
        self.date = date
        expires = ttl.map { date.addingTimeInterval($0) }
        subtitle = content.subtitle
        markdown = text("markdown")
        level = content.interruptionLevel.displayName
        url = text("url")
        image = text("image")
        usedCriticalAlertFallback = info[Self.criticalAlertFallbackKey] as? Bool
    }

    // Defined here rather than in WatchNotification because the complication
    // target compiles this file without it.
    static let criticalAlertFallbackKey = "bark_watch_critical_fallback"
}

nonisolated extension UNNotificationInterruptionLevel {
    var displayName: String {
        switch self {
        case .passive: "Passive"
        case .timeSensitive: "Time sensitive"
        case .critical: "Critical"
        default: "Active"
        }
    }
}

nonisolated struct WatchArchive: Sendable {
    static let widgetKind = "BarkWatchComplication"
    /// Opened by tapping the complication; `id` names the archived message it shows.
    static let messageURLHost = "message"

    static func messageURL(id: String?) -> URL {
        var components = URLComponents()
        components.scheme = "bark-watch"
        components.host = messageURLHost
        components.queryItems = id.map { [URLQueryItem(name: "id", value: $0)] }
        return components.url ?? URL(string: "bark-watch://message")!
    }
    static let shared = WatchArchive(directory: FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: "group.com.sebersta.BarkWatchPrototype"))
    let directory: URL?

    func messages(at date: Date = .now) throws -> [WatchArchivedMessage] {
        guard let directory else { throw CocoaError(.fileNoSuchFile) }
        let url = directory.appendingPathComponent("recent_messages.json")
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        return try JSONDecoder().decode([WatchArchivedMessage].self, from: Data(contentsOf: url))
            .filter { $0.expires.map { $0 > date } ?? true }
    }

    func save(_ message: WatchArchivedMessage) throws {
        _ = try updateMessages { items in
            items.removeAll { $0.id == message.id }
            items.append(message)
            return true
        }
    }

    @discardableResult
    func remove(id: String) throws -> Bool {
        guard !id.isEmpty else { return false }
        return try updateMessages { items in
            let previousCount = items.count
            items.removeAll { $0.id == id }
            return items.count != previousCount
        }
    }

    private func updateMessages(_ update: (inout [WatchArchivedMessage]) -> Bool) throws -> Bool {
        guard let directory else { throw CocoaError(.fileNoSuchFile) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        // A file lock covers separate notification-service processes; atomic replacement protects readers.
        let descriptor = open(directory.appendingPathComponent("archive.lock").path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
        guard descriptor >= 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        defer { close(descriptor) }
        guard flock(descriptor, LOCK_EX) == 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        defer { flock(descriptor, LOCK_UN) }
        var items = try messages()
        guard update(&items) else { return false }
        items.sort { $0.date > $1.date }
        // ponytail: retain 100 recent notifications, matching the phone widget snapshot.
        let data = try JSONEncoder().encode(Array(items.prefix(100)))
        try data.write(to: directory.appendingPathComponent("recent_messages.json"),
                       options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        return true
    }

    func latest(group: String?, at date: Date = .now) throws -> WatchArchivedMessage? {
        try messages(at: date).first { group == nil || $0.group == group }
    }

    func message(id: String, at date: Date = .now) throws -> WatchArchivedMessage? {
        try messages(at: date).first { $0.id == id }
    }
}
