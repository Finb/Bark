//
//  MuteProcessor.swift
//  NotificationServiceExtension
//
//  Created by huangfeng on 11/6/24.
//  Copyright © 2024 Fin. All rights reserved.
//

import UIKit

class MuteProcessor: NotificationContentProcessor {
    func process(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
        let groupName = bestAttemptContent.threadIdentifier
        guard let date = GroupMuteSettingManager().settings[groupName], date > Date() else {
            return bestAttemptContent
        }
        // 需要静音
        if #available(iOSApplicationExtension 15.0, *) {
            bestAttemptContent.interruptionLevel = .passive
        }
        return bestAttemptContent
    }
}
