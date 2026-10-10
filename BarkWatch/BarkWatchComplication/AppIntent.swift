//
//  AppIntent.swift
//  BarkWatchComplication
//
//  Created by Jian Qin on 9/28/26.
//

import AppIntents

struct ArchiveGroup: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Notification group" }
    static var defaultQuery: ArchiveGroupQuery { ArchiveGroupQuery() }
    let id: String
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
    var name: String { id == "all" ? "All groups" : id == "group:" ? "Ungrouped" : String(id.dropFirst(6)) }
    var filter: String? { id == "all" ? nil : String(id.dropFirst(6)) }
    static let all = ArchiveGroup(id: "all")
}

struct ArchiveGroupQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [ArchiveGroup] {
        identifiers.filter { $0 == "all" || $0.hasPrefix("group:") }.map { ArchiveGroup(id: $0) }
    }
    func suggestedEntities() async throws -> [ArchiveGroup] {
        let groups = Set(try WatchArchive.shared.messages().map(\.group)).sorted()
        return [.all] + groups.map { ArchiveGroup(id: "group:" + $0) }
    }
    func defaultResult() async -> ArchiveGroup? { .all }
}

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Latest notification" }
    static var description: IntentDescription { "Show the newest archived notification from a group." }

    @Parameter(title: "Group") var group: ArchiveGroup?
}
