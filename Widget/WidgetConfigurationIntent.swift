//
//  WidgetConfigurationIntent.swift
//  WidgetExtension
//
//  Created by OpenCode on 2026/3/30.
//

import AppIntents
import Foundation

private let widgetDefaultGroupValue = NSLocalizedString("all", comment: "")

func loadWidgetHistorySnapshot() -> WidgetHistorySnapshot? {
    guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WidgetHistoryConstants.appGroupIdentifier)?.appendingPathComponent(WidgetHistoryConstants.snapshotFilename),
          let data = try? Data(contentsOf: url)
    else {
        return nil
    }

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try? decoder.decode(WidgetHistorySnapshot.self, from: data)
}

@available(iOS 17.0, *)
struct WidgetGroupOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> [String] {
        [widgetDefaultGroupValue] + (loadWidgetHistorySnapshot()?.availableGroups ?? [])
    }

    func defaultResult() async -> String? {
        widgetDefaultGroupValue
    }
}

@available(iOS 17.0, *)
struct WidgetGroupSelectionIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "widget.configuration.displayName"
    static var description = IntentDescription("widget.configuration.description")

    @Parameter(title: "group", optionsProvider: WidgetGroupOptionsProvider())
    var group: String?

    init() {
        group = widgetDefaultGroupValue
    }
}

@available(iOS 17.0, *)
extension WidgetGroupSelectionIntent {
    var selectedGroup: String? {
        guard let group, group != widgetDefaultGroupValue else {
            return nil
        }
        return group
    }
}
