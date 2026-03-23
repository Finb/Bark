//
//  BarkWatchMessage.swift
//  Bark
//
//  Created by Codex on 2026/3/22.
//

import Foundation

struct BarkWatchMessage: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let title: String
    let body: String
    let timestamp: TimeInterval
}

enum BarkWatchSyncPayload {
    static let messagesKey = "barkWatchMessages"
    static let requestSnapshotKey = "requestSnapshot"
    static let generatedAtKey = "generatedAt"
    static let messageCountKey = "messageCount"
}
