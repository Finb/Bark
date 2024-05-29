//
//  NotificationService.swift
//  NotificationServiceExtension
//
//  Created by huangfeng on 2018/12/17.
//  Copyright © 2018 Fin. All rights reserved.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        Task {
            guard var bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent) else {
                contentHandler(request.content)
                return
            }
            
            let processors: [NotificationContentProcessorItem] = [
                .ciphertext,
                .level,
                .badge,
                .autoCopy,
                .archive,
                .setIcon,
                .setImage
            ]
            
            for item in processors {
                do {
                    bestAttemptContent = try await item.processor.process(content: bestAttemptContent)
                } catch NotificationContentProcessorError.error(let content) {
                    contentHandler(content)
                    return
                }
            }
            
            contentHandler(bestAttemptContent)
        }
    }
}
