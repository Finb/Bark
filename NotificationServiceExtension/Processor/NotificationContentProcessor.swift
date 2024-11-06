//
//  NotificationContentProcessor.swift
//  NotificationServiceExtension
//
//  Created by huangfeng on 2024/5/29.
//  Copyright © 2024 Fin. All rights reserved.
//

import Foundation
@_exported import UserNotifications

enum NotificationContentProcessorItem {
    case ciphertext
    case level
    case badge
    case autoCopy
    case archive
    case setIcon
    case setImage
    case call
    case mute
    
    var processor: NotificationContentProcessor {
        switch self {
        case .ciphertext:
            return CiphertextProcessor()
        case .level:
            return LevelProcessor()
        case .badge:
            return BadgeProcessor()
        case .autoCopy:
            return AutoCopyProcessor()
        case .archive:
            return ArchiveProcessor()
        case .setIcon:
            return IconProcessor()
        case .setImage:
            return ImageProcessor()
        case .call:
            return CallProcessor()
        case .mute:
            return MuteProcessor()
        }
    }
}

enum NotificationContentProcessorError: Swift.Error {
    case error(content: UNMutableNotificationContent)
}

public protocol NotificationContentProcessor {
    /// 处理 UNMutableNotificationContent
    /// - Parameters:
    ///   - identifier: request.identifier, 有些 Processor 需要，例如 CallProcessor 需要这个去添加 LocalNotification
    ///   - bestAttemptContent: 需要处理的 UNMutableNotificationContent
    /// - Returns: 处理成功后的 UNMutableNotificationContent
    /// - Throws: 处理失败后，应该中断处理
    func process(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent
    
    /// serviceExtension 即将终止，不管 processor 是否处理完成，最好立即调用 contentHandler 交付已完成的部分，否则会原样展示服务器传递过来的推送
    func serviceExtensionTimeWillExpire(contentHandler: (UNNotificationContent) -> Void)
}

extension NotificationContentProcessor {
    func serviceExtensionTimeWillExpire(contentHandler: (UNNotificationContent) -> Void) {}
}
