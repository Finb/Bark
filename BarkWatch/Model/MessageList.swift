import Foundation
import Observation

@MainActor
@Observable
final class MessageList {
    private(set) var items: [MessageItem] = []
    private(set) var groupFilters: [MessageFilter] = [.all]
    private(set) var hasMore = false
    private(set) var filter: MessageFilter = .all

    private var cursor: MessageStore.PageCursor?
    private var isLoadingMore = false

    func reload() {
        let store = MessageStore.shared
        store.pruneExpired(now: Date())

        groupFilters = [.all] + store.fetchGroups().map { .group($0.key) }

        if !groupFilters.contains(filter) {
            filter = .all
        }

        loadFirstPage(from: store)
    }

    func select(_ newFilter: MessageFilter) {
        guard newFilter != filter else { return }
        filter = newFilter
        loadFirstPage(from: .shared)
    }

    @discardableResult
    func clear(_ range: MessageDeleteTimeRange) -> Int {
        let deleted = MessageStore.shared.deleteMessages(
            filter: filter,
            startDate: range.startDate,
            endDate: range.endDate
        )
        reload()
        return deleted
    }

    func loadMore() {
        guard hasMore, !isLoadingMore, let cursor else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        let page = MessageStore.shared.fetchPage(filter: filter, before: cursor)
        items.append(contentsOf: page.items)
        self.cursor = page.items.last.map { MessageStore.PageCursor(createDate: $0.createDate, id: $0.id) }
        hasMore = page.hasMore
    }

    private func loadFirstPage(from store: MessageStore) {
        let page = store.fetchPage(filter: filter, before: nil)
        items = page.items
        cursor = page.items.last.map { MessageStore.PageCursor(createDate: $0.createDate, id: $0.id) }
        hasMore = page.hasMore
    }
}
