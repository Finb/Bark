import Foundation
import SwiftData

enum MessageFilter: Hashable {
    case all
    case group(String)
}

@MainActor
final class MessageStore {
    static let shared = MessageStore()

    static let pageSize = 50

    struct PageCursor {
        let createDate: Date
        let id: String
    }

    private let context: ModelContext?

    private init() {
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.bark") else {
            context = nil
            return
        }
        let directory = groupURL.appendingPathComponent("BarkWatch", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let configuration = ModelConfiguration(url: directory.appendingPathComponent("Messages.store"))
        guard let container = try? ModelContainer(
            for: WatchMessage.self,
            WatchGroup.self,
            configurations: configuration
        ) else {
            context = nil
            return
        }
        context = ModelContext(container)
    }

    func save(_ message: WatchMessage) {
        guard let context else { return }
        let id = message.id
        var descriptor = FetchDescriptor<WatchMessage>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1

        if let current = (try? context.fetch(descriptor))?.first {
            current.title = message.title
            current.subtitle = message.subtitle
            current.body = message.body
            current.url = message.url
            current.image = message.image
            current.createDate = message.createDate
            current.expireDate = message.expireDate

            if current.group != message.group {
                current.group = message.group
                reconcileGroups(in: context)
            }
        } else {
            context.insert(message)
        }

        upsertGroup(message.group, date: message.createDate, in: context)
        try? context.save()
    }

    func fetchPage(
        filter: MessageFilter,
        before cursor: PageCursor?,
        limit: Int = MessageStore.pageSize
    ) -> (items: [MessageItem], hasMore: Bool) {
        guard let context else { return ([], false) }

        var descriptor = FetchDescriptor<WatchMessage>(
            predicate: pagePredicate(filter: filter, before: cursor),
            sortBy: [
                SortDescriptor(\.createDate, order: .reverse),
                SortDescriptor(\.id, order: .reverse)
            ]
        )
        descriptor.fetchLimit = limit + 1

        let fetched = (try? context.fetch(descriptor)) ?? []
        let items = fetched.prefix(limit).map(MessageItem.init)
        return (Array(items), fetched.count > limit)
    }

    func fetchGroups() -> [WatchGroup] {
        guard let context else { return [] }
        let descriptor = FetchDescriptor<WatchGroup>(
            sortBy: [SortDescriptor(\.latestDate, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    @discardableResult
    func pruneExpired(now: Date) -> Int {
        deleteMessages(
            predicate: #Predicate { message in
                message.expireDate != nil && message.expireDate! <= now
            },
            batchSize: 500
        )
    }

    @discardableResult
    func deleteMessages(filter: MessageFilter, startDate: Date, endDate: Date) -> Int {
        let predicate: Predicate<WatchMessage>
        switch filter {
        case .all:
            predicate = #Predicate { message in
                message.createDate >= startDate && message.createDate <= endDate
            }
        case .group(let key):
            predicate = #Predicate { message in
                message.group == key &&
                    message.createDate >= startDate && message.createDate <= endDate
            }
        }
        return deleteMessages(predicate: predicate)
    }

    @discardableResult
    func deleteMessages(predicate: Predicate<WatchMessage>, batchSize: Int? = nil) -> Int {
        guard let context else { return 0 }

        var deleted = 0
        while true {
            var descriptor = FetchDescriptor<WatchMessage>(predicate: predicate)
            descriptor.fetchLimit = batchSize
            guard let batch = try? context.fetch(descriptor), !batch.isEmpty else { break }
            for message in batch {
                context.delete(message)
            }
            deleted += batch.count
            try? context.save()
            if batchSize == nil { break }
        }

        if deleted > 0 {
            reconcileGroups(in: context)
        }
        return deleted
    }

    private func upsertGroup(_ key: String, date: Date, in context: ModelContext) {
        var descriptor = FetchDescriptor<WatchGroup>(predicate: #Predicate { $0.key == key })
        descriptor.fetchLimit = 1
        if let group = (try? context.fetch(descriptor))?.first {
            if group.latestDate < date {
                group.latestDate = date
            }
        } else {
            context.insert(WatchGroup(key: key, latestDate: date))
        }
    }

    private func reconcileGroups(in context: ModelContext) {
        let groups = (try? context.fetch(FetchDescriptor<WatchGroup>())) ?? []
        for group in groups {
            let key = group.key
            var descriptor = FetchDescriptor<WatchMessage>(
                predicate: #Predicate { $0.group == key }
            )
            descriptor.sortBy = [SortDescriptor(\.createDate, order: .reverse)]
            descriptor.fetchLimit = 1

            if let latest = (try? context.fetch(descriptor))?.first {
                group.latestDate = latest.createDate
            } else {
                context.delete(group)
            }
        }
        try? context.save()
    }

    private func pagePredicate(filter: MessageFilter, before cursor: PageCursor?) -> Predicate<WatchMessage>? {
        switch (filter, cursor) {
        case (.all, nil):
            return nil
        case (.all, let cursor?):
            return cursorPredicate(cursor)
        case (.group(let key), nil):
            return #Predicate { message in message.group == key }
        case (.group(let key), let cursor?):
            let date = cursor.createDate
            let id = cursor.id
            return #Predicate { message in
                message.group == key &&
                    (message.createDate < date || (message.createDate == date && message.id < id))
            }
        }
    }

    private func cursorPredicate(_ cursor: PageCursor) -> Predicate<WatchMessage> {
        let date = cursor.createDate
        let id = cursor.id
        return #Predicate { message in
            message.createDate < date || (message.createDate == date && message.id < id)
        }
    }
}
