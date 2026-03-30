//
//  Widget.swift
//  Widget
//
//  Created by huangfeng on 3/23/26.
//  Copyright © 2026 Fin. All rights reserved.
//

import SwiftUI
import WidgetKit

@available(iOS 17.0, *)
struct Provider: AppIntentTimelineProvider {
    typealias Intent = WidgetGroupSelectionIntent

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: .now, snapshot: .placeholder, selectedGroup: nil)
    }

    func snapshot(for configuration: WidgetGroupSelectionIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: .now,
                    snapshot: loadWidgetHistorySnapshot() ?? .placeholder,
                    selectedGroup: configuration.selectedGroup)
    }

    func timeline(for configuration: WidgetGroupSelectionIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let entry = SimpleEntry(date: .now,
                                snapshot: loadWidgetHistorySnapshot() ?? .empty,
                                selectedGroup: configuration.selectedGroup)
        return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60)))
    }
}

struct WidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        ZStack(alignment: .topLeading) {
            switch family {
            case .systemSmall:
                SmallRecentMessagesView(entry: entry)
            case .systemMedium:
                MediumRecentMessagesView(entry: entry)
            default:
                MediumRecentMessagesView(entry: entry)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(WidgetDeepLink.history())
        .modifier(WidgetContainerBackground())
    }
}

private struct WidgetContainerBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            content.containerBackground(for: .widget) {
                Color(uiColor: .systemBackground)
            }
        } else {
            content.background(Color(uiColor: .systemBackground))
        }
    }
}

private struct MediumRecentMessagesView: View {
    let entry: SimpleEntry

    var body: some View {
        if let message = entry.snapshot.recentMessages(in: entry.selectedGroup).first {
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .center, spacing: 5) {
                    WidgetHeaderView(title: message.group ?? "Bark", icon: "app.badge.fill")

                    Spacer(minLength: 0)

                    TimeBadgeView(date: message.createDate)

                    if message.image != nil {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.accentColor)
                    }
                }

                if let titleText = message.title {
                    Text(titleText)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .layoutPriority(2)
                }

                if let subtitle = message.subtitle {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .layoutPriority(1)
                }

                if let bodyText = message.body {
                    Text(bodyText)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(nil)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else {
            EmptyRecentMessagesView()
        }
    }
}

private struct SmallRecentMessagesView: View {
    let entry: SimpleEntry

    var body: some View {
        if let message = entry.snapshot.recentMessages(in: entry.selectedGroup).first {
            VStack(alignment: .leading, spacing: 5) {
                WidgetHeaderView(title: message.group ?? "Bark", icon: "app.badge.fill")
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        if let titleText = message.title {
                            Text(titleText)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .layoutPriority(2)
                        }
                        
                        if let subtitle = message.subtitle {
                            Text(subtitle)
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .layoutPriority(1)
                        }
                        
                        if let bodyText = message.body {
                            Text(bodyText)
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundStyle(.secondary)
                                .lineLimit(nil)
                                .truncationMode(.tail)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    Spacer(minLength: 0)

                    TimeBadgeView(date: message.createDate)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else {
            EmptyRecentMessagesView()
        }
    }
}

private struct WidgetHeaderView: View {
    let title: String
    var icon: String? = nil

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.tint)
            }
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
    }
}

private struct TimeBadgeView: View {
    let date: Date

    var body: some View {
        Text(date, style: .relative)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(.secondary)
    }
}

private struct EmptyRecentMessagesView: View {
    private let title = NSLocalizedString("widget.empty.title", comment: "")
    private let subtitle = NSLocalizedString("widget.empty.subtitle", comment: "")

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Color.accentColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
            }

            Spacer(minLength: 0)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

enum WidgetDeepLink {
    static func history() -> URL {
        return URL(string: "bark://history")!
    }
}

struct RecentMessagesWidget: Widget {
    let kind: String = "RecentMessagesWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: WidgetGroupSelectionIntent.self, provider: Provider()) { entry in
            WidgetEntryView(entry: entry)
        }
        .configurationDisplayName(NSLocalizedString("widget.configuration.displayName", comment: ""))
        .description(NSLocalizedString("widget.description", comment: ""))
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

@available(iOS 17.0, *)
#Preview(as: .systemSmall) {
    RecentMessagesWidget()
} timeline: {
    SimpleEntry(date: .now, snapshot: .placeholder, selectedGroup: nil)
}

@available(iOS 17.0, *)
#Preview(as: .systemMedium) {
    RecentMessagesWidget()
} timeline: {
    SimpleEntry(date: .now, snapshot: .placeholder, selectedGroup: nil)
}
