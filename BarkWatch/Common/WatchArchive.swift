//
//  WatchArchive.swift
//  Bark
//
//  Created by Jian Qin on 9/30/26.
//

import Foundation
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
    let level: WatchNotificationLevel?
    let url: String?
    let image: String?
    let usedCriticalAlertFallback: Bool?

    /// Expects content already prepared by `WatchNotification.prepare`, so the
    /// body, group, and interruption level match what was delivered. Encrypted
    /// pushes arrive here already decrypted and are archived like the phone does.
    init?(content: UNNotificationContent, identifier: String, date: Date = .now) {
        let info = content.userInfo
        func text(_ key: String) -> String? {
            (info[key] as? String) ?? (info[key] as? NSNumber)?.stringValue
        }
        guard text("isarchive").map({ $0 == "1" }) ?? true,
              text("delete") != "1" else { return nil }
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
        level = WatchNotificationLevel(content.interruptionLevel)
        url = text("url")
        image = text("image")
        usedCriticalAlertFallback = info[Self.criticalAlertFallbackKey] as? Bool
    }

    static let criticalAlertFallbackKey = "bark_watch_critical_fallback"
}

/// The interruption level a message was delivered with, as shown in the app.
/// The raw values are stored in the archive, so don't change them.
nonisolated enum WatchNotificationLevel: String, Codable, Sendable {
    case passive = "Passive"
    case active = "Active"
    case timeSensitive = "Time sensitive"
    case critical = "Critical"

    init(_ level: UNNotificationInterruptionLevel) {
        switch level {
        case .passive: self = .passive
        case .timeSensitive: self = .timeSensitive
        case .critical: self = .critical
        default: self = .active
        }
    }
}

nonisolated struct WatchArchive: Sendable {
    static let shared = WatchArchive(directory: FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: WatchConstants.appGroupIdentifier))
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
        let data = try JSONEncoder().encode(Array(items.prefix(100)))
        try data.write(to: directory.appendingPathComponent("recent_messages.json"),
                       options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        return true
    }

    func latest(group: String?, at date: Date = .now) throws -> WatchArchivedMessage? {
        try messages(at: date).first { group == nil || $0.group == group }
    }
}
