//
//  MessageDeletionCoordinator.swift
//  Bark
//

import RealmSwift

enum MessageDeletionCoordinator {
    /// Deletes the specified messages and waits for their unreferenced image caches to be removed.
    @MainActor
    static func delete(ids: [String]) async throws {
        guard !ids.isEmpty else { return }

        let realm = try await Realm()
        let messages = realm.objects(Message.self).filter("id IN %@", ids)
        let imageUrls = try deleteInCurrentRealm(messages, in: realm)
        await WidgetHistorySnapshotStore.shared.refreshFromRealmAsync()
        await removeImageCaches(imageUrls)
    }

    static func removeImageCaches(_ imageUrls: [String]) async {
        await MessageImageCleaner.shared.removeUnreferencedImages(imageUrls)
    }

    /// Deletes messages and performs any related writes in one Realm transaction.
    static func deleteInCurrentRealm(
        _ messages: Results<Message>,
        in realm: Realm
    ) throws -> [String] {
        let imageUrls = MessageImageCleaner.shared.imageUrls(in: messages)
        guard !messages.isEmpty else { return [] }

        try realm.write {
            realm.delete(messages)
        }
        return imageUrls
    }
}
