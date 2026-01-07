//
//  NotificationService.swift
//  NotificationServiceExtension
//
//  Created by huangfeng on 2018/12/17.
//  Copyright © 2018 Fin. All rights reserved.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    /// 当前 ContentHandler，主要用来 serviceExtensionTimeWillExpire 时交付推送
    var currentContentHandler: ((UNNotificationContent) -> Void)? = nil
    /// 当前正在处理的推送内容
    var currentBestAttemptContent: UNMutableNotificationContent? = nil
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        Task {
            guard var bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent) else {
                contentHandler(request.content)
                return
            }
            self.currentContentHandler = contentHandler
            
            // 所有的 processor 按顺序从上往下对推送进行处理
            // ciphertext 需要放在最前面，有可能所有的推送数据都在密文里
            // icon 放在最后面，游戏模式下可能会超时，超时后后面的 processor 就没机会运行了。
            let processors: [NotificationContentProcessorItem] = [
                .ciphertext,
                .markdown,
                .level,
                .badge,
                .autoCopy,
                .archive,
                .mute,
                .call,
                .setImage,
                .setIcon
            ]
            
            // 各个 processor 依次对推送进行处理
            for processor in processors.map({ $0.processor }) {
                do {
                    bestAttemptContent = try await processor.process(identifier: request.identifier, content: bestAttemptContent)
                    self.currentBestAttemptContent = bestAttemptContent
                } catch NotificationContentProcessorError.error(let content) {
                    contentHandler(content)
                    return
                }
            }
            
            // 处理完后交付推送
            contentHandler(bestAttemptContent)
            
            // 发送 Darwin Notification 通知主 APP 有新消息
            CFNotificationCenterPostNotification(
                CFNotificationCenterGetDarwinNotifyCenter(),
                CFNotificationName("com.bark.newmessage" as CFString),
                nil,
                nil,
                true
            )
        }
    }

    override func serviceExtensionTimeWillExpire() {
        super.serviceExtensionTimeWillExpire()
        guard let contentHandler = currentContentHandler,
              let bestAttemptContent = currentBestAttemptContent
        else {
            return
        }
        contentHandler(bestAttemptContent)
    }
}
