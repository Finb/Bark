//
//  AutoCopyProcessor.swift
//  NotificationServiceExtension
//
//  Created by huangfeng on 2024/5/29.
//  Copyright © 2024 Fin. All rights reserved.
//

import Foundation

class AutoCopyProcessor: NotificationContentProcessor {
    func process(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
        let userInfo = bestAttemptContent.userInfo
        if userInfo["autocopy"] as? String == "1"
            || userInfo["automaticallycopy"] as? String == "1"
        {
            if let copy = userInfo["copy"] as? String {
                UIPasteboard.general.string = copy
            } else {
                UIPasteboard.general.string = bestAttemptContent.body
            }
        }
        return bestAttemptContent
    }
}
