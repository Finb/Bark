//
//  BarkWatchSessionManager.swift
//  BarkWatch Watch App Extension
//
//  Created by Codex on 2026/3/22.
//

import Combine
import Foundation
import WatchConnectivity

final class BarkWatchSessionManager: NSObject, ObservableObject {
    @Published private(set) var messages: [BarkWatchMessage] = []
    @Published private(set) var syncStatus = "Waiting for messages"

    private enum Constants {
        static let cacheKey = "barkWatchMessagesCache"
    }

    private var isRetryScheduled = false

    override init() {
        super.init()
        restoreCachedMessages()
        activateSession()
    }

    private func activateSession() {
        guard WCSession.isSupported() else {
            syncStatus = "WatchConnectivity unavailable"
            return
        }

        let session = WCSession.default
        session.delegate = self
        syncStatus = "Connecting to iPhone"
        session.activate()
        handle(context: session.receivedApplicationContext)
    }

    func requestSync() {
        let session = WCSession.default
        guard session.activationState == .activated else {
            updateSyncStatus("Connecting to iPhone")
            activateSession()
            scheduleRetry()
            return
        }
        guard session.isReachable else {
            updateSyncStatus(messages.isEmpty ? "Open Bark on iPhone to sync." : "Showing latest synced messages")
            handle(context: session.receivedApplicationContext)
            return
        }

        updateSyncStatus("Syncing messages")
        session.sendMessage([BarkWatchSyncPayload.requestSnapshotKey: true], replyHandler: { [weak self] context in
            self?.handle(context: context)
        }, errorHandler: { [weak self] _ in
            self?.updateSyncStatus(self?.messages.isEmpty == true ? "Open Bark on iPhone to sync." : "Showing latest synced messages")
            self?.handle(context: session.receivedApplicationContext)
        })
    }

    private func restoreCachedMessages() {
        guard let data = UserDefaults.standard.data(forKey: Constants.cacheKey) else {
            return
        }
        decodeMessages(from: data)
    }

    private func handle(context: [String: Any]) {
        guard let items = context[BarkWatchSyncPayload.messagesKey] as? [[String: Any]] else {
            return
        }
        let messages = items.compactMap { item -> BarkWatchMessage? in
            guard let id = item["id"] as? String,
                  let title = item["title"] as? String,
                  let body = item["body"] as? String,
                  let timestamp = item["timestamp"] as? TimeInterval
            else {
                return nil
            }
            return BarkWatchMessage(id: id, title: title, body: body, timestamp: timestamp)
        }
        guard let data = try? JSONEncoder().encode(messages) else {
            return
        }
        UserDefaults.standard.set(data, forKey: Constants.cacheKey)
        let generatedAt = context[BarkWatchSyncPayload.generatedAtKey] as? TimeInterval
        let count = (context[BarkWatchSyncPayload.messageCountKey] as? Int) ?? messages.count
        DispatchQueue.main.async {
            self.messages = messages
            if count == 0 {
                self.syncStatus = "No messages yet"
            } else if let generatedAt {
                self.syncStatus = "Updated \(Self.timeFormatter.string(from: Date(timeIntervalSince1970: generatedAt)))"
            } else {
                self.syncStatus = "Updated \(Self.timeFormatter.string(from: Date()))"
            }
        }
    }

    private func decodeMessages(from data: Data) {
        let decoder = JSONDecoder()
        guard let messages = try? decoder.decode([BarkWatchMessage].self, from: data) else {
            return
        }
        DispatchQueue.main.async {
            self.messages = messages
        }
    }

    private func updateSyncStatus(_ text: String) {
        DispatchQueue.main.async {
            self.syncStatus = text
        }
    }

    private func scheduleRetry() {
        guard !isRetryScheduled else {
            return
        }
        isRetryScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            self.isRetryScheduled = false
            self.requestSync()
        }
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter
    }()
}

extension BarkWatchSessionManager: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        updateSyncStatus(error == nil ? "Connected to iPhone" : "Unable to connect to iPhone")
        handle(context: session.receivedApplicationContext)
        requestSync()
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        handle(context: applicationContext)
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        updateSyncStatus(session.isReachable ? "Connected to iPhone" : "Showing latest synced messages")
        requestSync()
    }
}
