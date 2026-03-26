//
//  WidgetHistorySnapshotStore.swift
//  Bark
//
//  Created by OpenCode on 2026/3/23.
//

import Foundation

#if canImport(WidgetKit)
import WidgetKit
#endif

enum WidgetHistoryConstants {
    static let appGroupIdentifier = "group.bark"
    static let snapshotFilename = "recent_messages_snapshot.json"
    static let widgetKind = "RecentMessagesWidget"
    static let maxItems = 3
}

final class WidgetHistorySnapshotStore {
    static let shared = WidgetHistorySnapshotStore()

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    private var snapshotURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: WidgetHistoryConstants.appGroupIdentifier)?
            .appendingPathComponent(WidgetHistoryConstants.snapshotFilename)
    }
    private init() {}

    func syncFromMessages(_ messages: [WidgetHistoryMessage], limit: Int = WidgetHistoryConstants.maxItems) {
        let items = Array(messages.sorted { $0.createDate > $1.createDate }.prefix(limit))
        write(WidgetHistorySnapshot(messages: items))
    }

    func prependMessage(_ message: WidgetHistoryMessage, limit: Int = WidgetHistoryConstants.maxItems) {
        var items = load()?.messages ?? []
        items.removeAll { $0.id == message.id }
        items.insert(message, at: 0)
        let deduplicated = Array(items.sorted { $0.createDate > $1.createDate }.prefix(limit))
        write(WidgetHistorySnapshot(messages: deduplicated))
    }

    private func load() -> WidgetHistorySnapshot? {
        guard let url = snapshotURL,
              let data = try? Data(contentsOf: url)
        else {
            return nil
        }
        return try? decoder.decode(WidgetHistorySnapshot.self, from: data)
    }

    private func write(_ snapshot: WidgetHistorySnapshot) {
        guard let url = snapshotURL,
              let data = try? encoder.encode(snapshot)
        else {
            return
        }

        try? data.write(to: url, options: .atomic)
        reloadWidget()
    }

    private func reloadWidget() {
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetHistoryConstants.widgetKind)
        }
    }
}
