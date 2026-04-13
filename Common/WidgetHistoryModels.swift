//
//  WidgetHistoryModels.swift
//  Bark
//
//  Created by OpenCode on 2026/3/26.
//

import Foundation

enum WidgetHistoryConstants {
    static let appGroupIdentifier = "group.bark"
    static let snapshotFilename = "recent_messages_snapshot.json"
    static let widgetKind = "RecentMessagesWidget"
    static let displayLimit = 3
    static let snapshotRetentionLimit = 100
    static let bodyCharacterLimit = 500
}

private extension String {
    func trimmedForWidget(limit: Int = WidgetHistoryConstants.bodyCharacterLimit) -> String {
        let normalized = trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.count > limit else {
            return normalized
        }
        return String(normalized.prefix(limit))
    }
}

struct WidgetHistoryMessage: Codable, Identifiable {
    let id: String
    let group: String?
    let title: String?
    let subtitle: String?
    let body: String?
    let image: String?
    let createDate: Date

    init(id: String,
         group: String?,
         title: String?,
         subtitle: String?,
         body: String?,
         image: String?,
         createDate: Date)
    {
        self.id = id
        self.group = group
        self.title = title
        self.subtitle = subtitle
        self.body = body?.trimmedForWidget()
        self.image = image
        self.createDate = createDate
    }
}

struct WidgetHistorySnapshot: Codable {
    let messages: [WidgetHistoryMessage]

    func recentMessages(in group: String?, limit: Int = WidgetHistoryConstants.displayLimit) -> [WidgetHistoryMessage] {
        let filteredMessages: [WidgetHistoryMessage]
        if let group {
            filteredMessages = messages.filter { $0.group == group }
        } else {
            filteredMessages = messages
        }

        return Array(filteredMessages.prefix(limit))
    }

    var availableGroups: [String] {
        messages.reduce(into: [String]()) { result, message in
            guard let group = message.group, !group.isEmpty, !result.contains(group) else {
                return
            }
            result.append(group)
        }
    }
}
