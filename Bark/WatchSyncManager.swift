//
//  WatchSyncManager.swift
//  Bark
//
//  Created by Codex on 2026/3/22.
//

import Foundation
import RealmSwift
import WatchConnectivity

final class WatchSyncManager: NSObject {
    static let shared = WatchSyncManager()

    private enum Constants {
        static let maxMessages = 20
    }

    private let syncQueue = DispatchQueue(label: "me.fin.bark.watch-sync", qos: .utility)
    private var hasPendingSync = false

    private override init() {
        super.init()
    }

    func start() {
        guard WCSession.isSupported() else {
            return
        }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        syncRecentMessages()
    }

    func syncRecentMessages() {
        syncQueue.async { [weak self] in
            guard let self else { return }
            guard WCSession.isSupported() else { return }

            let session = WCSession.default
            guard session.activationState == .activated else {
                self.hasPendingSync = true
                if session.delegate == nil {
                    session.delegate = self
                }
                session.activate()
                return
            }

            let messages = self.loadRecentMessages()
            do {
                let context = self.applicationContext(from: messages)
                try session.updateApplicationContext(context)
                if session.isReachable {
                    session.sendMessage(context, replyHandler: nil, errorHandler: nil)
                }
                self.hasPendingSync = false
            } catch {
                self.hasPendingSync = true
            }
        }
    }

    private func applicationContext(from messages: [BarkWatchMessage]) -> [String: Any] {
        let items = messages.map { message in
            [
                "id": message.id,
                "title": message.title,
                "body": message.body,
                "timestamp": message.timestamp
            ]
        }
        return [
            BarkWatchSyncPayload.messagesKey: items,
            BarkWatchSyncPayload.generatedAtKey: Date().timeIntervalSince1970,
            BarkWatchSyncPayload.messageCountKey: items.count
        ]
    }

    private func loadRecentMessages() -> [BarkWatchMessage] {
        guard let realm = try? Realm() else {
            return []
        }

        return realm.objects(Message.self)
            .sorted(byKeyPath: "createDate", ascending: false)
            .prefix(Constants.maxMessages)
            .map { message in
                BarkWatchMessage(
                    id: message.id,
                    title: message.title ?? "",
                    body: message.body ?? "",
                    timestamp: message.createDate?.timeIntervalSince1970 ?? 0
                )
            }
    }
}

extension WatchSyncManager: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if activationState == .activated, hasPendingSync {
            syncRecentMessages()
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        if session.isPaired || session.isReachable || session.isWatchAppInstalled {
            syncRecentMessages()
        }
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        guard message[BarkWatchSyncPayload.requestSnapshotKey] as? Bool == true else {
            replyHandler([:])
            return
        }

        let messages = loadRecentMessages()
        replyHandler(applicationContext(from: messages))
    }
}
