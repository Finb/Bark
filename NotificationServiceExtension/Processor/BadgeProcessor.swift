//
//  BadgeProcessor.swift
//  NotificationServiceExtension
//
//  Created by huangfeng on 2024/5/29.
//  Copyright © 2024 Fin. All rights reserved.
//

import Foundation

/// 通知角标
class BadgeProcessor: NotificationContentProcessor {
    func process(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
        if let badgeStr = bestAttemptContent.userInfo["badge"] as? String, let badge = Int(badgeStr) {
            bestAttemptContent.badge = NSNumber(value: badge)
        }
        return bestAttemptContent
    }
}
