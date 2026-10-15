//
//  ComplicationView.swift
//  BarkWatchComplication
//
//  Created by Jian Qin on 9/30/26.
//

import SwiftUI
import WidgetKit

struct BarkWatchComplicationEntryView: View {
    let entry: ArchiveEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // When one of title/body is empty, the other gets all 3 lines.
            if !entry.title.isEmpty {
                Text(verbatim: entry.title)
                    .lineLimit(entry.body.isEmpty ? 3 : 1, reservesSpace: true)
                    .font(.body.weight(.semibold))
            }
            if !entry.body.isEmpty {
                Text(verbatim: entry.body)
                    .lineLimit(entry.title.isEmpty ? 3 : 2, reservesSpace: true)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .privacySensitive()
        .containerBackground(entry.backgroundColor.gradient, for: .widget)
    }
}

struct ArchiveEntry: TimelineEntry {
    let date: Date
    let title: String
    let body: String
    let expires: Date?
    let messageID: String?
    let level: WatchNotificationLevel?

    /// Background follows the interruption level, matching the tint of `LastMessageView`.
    var backgroundColor: Color {
        switch level {
        case .critical: .red
        case .timeSensitive: .orange
        case .active, .passive, nil: .black
        }
    }

    static let preview = ArchiveEntry(
        date: .now,
        title: "Build finished",
        body: "All checks passed. Ready for testing on your watch.",
        expires: nil,
        messageID: nil,
        level: .critical
    )
}


#Preview(as: .accessoryRectangular) {
    BarkWatchComplication()
} timeline: {
    ArchiveEntry.preview
}
