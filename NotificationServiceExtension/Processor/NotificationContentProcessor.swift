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
        }
    }
}

enum NotificationContentProcessorError: Swift.Error {
    case error(content: UNMutableNotificationContent)
}

public protocol NotificationContentProcessor {
    /// 处理 UNMutableNotificationContent
    /// - Parameter bestAttemptContent: 需要处理的 UNMutableNotificationContent
    /// - Returns: 处理成功后的 UNMutableNotificationContent
    /// - Throws: 处理失败后，应该中断处理
    func process(content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent
}
