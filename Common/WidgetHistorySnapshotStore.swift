//
//  WidgetHistorySnapshotStore.swift
//  Bark
//
//  Created by OpenCode on 2026/3/23.
//

import Foundation
import RealmSwift
#if canImport(WidgetKit)
import WidgetKit
#endif

final class WidgetHistorySnapshotStore {
    static let shared = WidgetHistorySnapshotStore()

    private let accessQueue = DispatchQueue(label: "me.fin.bark.widget-history-snapshot", qos: .utility)

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

    func refreshFromRealmAsync(limit: Int = WidgetHistoryConstants.snapshotRetentionLimit) {
        accessQueue.async {
            guard let realm = try? Realm() else {
                return
            }
            let messages = realm.widgetSnapshotItems(limit: limit)
            self.syncFromMessagesLocked(messages, limit: limit)
        }
    }

    func prependMessage(_ message: WidgetHistoryMessage, limit: Int = WidgetHistoryConstants.snapshotRetentionLimit) {
        accessQueue.sync {
            prependMessageLocked(message, limit: limit)
        }
    }

    private func syncFromMessagesLocked(_ messages: [WidgetHistoryMessage], limit: Int) {
        let items = Array(messages.sorted { $0.createDate > $1.createDate }.prefix(limit))
        write(WidgetHistorySnapshot(messages: items))
    }

    private func prependMessageLocked(_ message: WidgetHistoryMessage, limit: Int) {
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
