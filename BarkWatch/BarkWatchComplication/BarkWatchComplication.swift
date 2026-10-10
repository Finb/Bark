//
//  BarkWatchComplication.swift
//  BarkWatchComplication
//
//  Created by Jian Qin on 9/30/26.
//

import WidgetKit
import SwiftUI


struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ArchiveEntry { .preview }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> ArchiveEntry {
        context.isPreview ? .preview : entry(for: configuration)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<ArchiveEntry> {
        let current = entry(for: configuration)
        let refresh = min(current.expires ?? .distantFuture, current.date.addingTimeInterval(15 * 60))
        return Timeline(entries: [current], policy: .after(refresh))
    }

    func recommendations() -> [AppIntentRecommendation<ConfigurationAppIntent>] {
        [AppIntentRecommendation(intent: ConfigurationAppIntent(), description: "Latest notification")]
    }

    private func entry(for configuration: ConfigurationAppIntent) -> ArchiveEntry {
        let date = Date()
        do {
            let message = try WatchArchive.shared.latest(group: configuration.group?.filter, at: date)
            return ArchiveEntry(date: date, title: message?.title ?? "Bark",
                body: message?.body ?? "No archived notifications", expires: message?.expires,
                messageID: message?.id, level: message?.level)
        } catch {
            return ArchiveEntry(date: date, title: "Bark", body: "Archive unavailable", expires: nil, messageID: nil,
                level: nil)
        }
    }
}


struct BarkWatchComplication: Widget {
    let kind = WatchArchive.widgetKind

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            BarkWatchComplicationEntryView(entry: entry)
                .widgetURL(WatchArchive.messageURL(id: entry.messageID))
        }
        .configurationDisplayName("Latest notification")
        .description("The newest archived notification in your selected group.")
        .supportedFamilies([.accessoryRectangular])
    }
}

