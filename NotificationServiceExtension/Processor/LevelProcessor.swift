//
//  LevelProcessor.swift
//  NotificationServiceExtension
//
//  Created by huangfeng on 2024/5/29.
//  Copyright © 2024 Fin. All rights reserved.
//

import Foundation

/// 通知中断级别
class LevelProcessor: NotificationContentProcessor {
    func process(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
        if #available(iOSApplicationExtension 15.0, *) {
            if let level = bestAttemptContent.userInfo["level"] as? String {
                let interruptionLevels: [String: UNNotificationInterruptionLevel] = [
                    "passive": UNNotificationInterruptionLevel.passive,
                    "active": UNNotificationInterruptionLevel.active,
                    "timeSensitive": UNNotificationInterruptionLevel.timeSensitive,
                    "timesensitive": UNNotificationInterruptionLevel.timeSensitive,
                    "critical": UNNotificationInterruptionLevel.critical
                ]
                bestAttemptContent.interruptionLevel = interruptionLevels[level] ?? .active
            }
        }
        return bestAttemptContent
    }
}
