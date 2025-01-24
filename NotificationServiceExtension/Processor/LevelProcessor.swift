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
        guard let level = bestAttemptContent.userInfo["level"] as? String else {
            return bestAttemptContent
        }
        
        if bestAttemptContent.isCritical {
            // 设置重要警告音效
            LevelProcessor.setCriticalSound(content: bestAttemptContent)
            return bestAttemptContent
        }
        
        // 其他的，例如时效性通知
        guard #available(iOSApplicationExtension 15.0, *) else {
            return bestAttemptContent
        }
        
        let interruptionLevels: [String: UNNotificationInterruptionLevel] = [
            "passive": UNNotificationInterruptionLevel.passive,
            "active": UNNotificationInterruptionLevel.active,
            "timeSensitive": UNNotificationInterruptionLevel.timeSensitive,
            "timesensitive": UNNotificationInterruptionLevel.timeSensitive
        ]
        bestAttemptContent.interruptionLevel = interruptionLevels[level] ?? .active
        return bestAttemptContent
    }
}

extension LevelProcessor {
    class func setCriticalSound(content bestAttemptContent: UNMutableNotificationContent, soundName: String? = nil) {
        guard bestAttemptContent.isCritical else {
            return
        }
        // 默认音量
        var audioVolume: Float = 0.5
        // 指定音量，取值范围是 0 - 10 , 会转换成 0.0 - 1.0
        if let volume = bestAttemptContent.userInfo["volume"] as? String, let volume = Float(volume) {
            audioVolume = max(0.0, min(1, volume / 10.0))
        }
        // 设置重要警告 sound
        let sound = soundName ?? bestAttemptContent.soundName
        if let sound {
            bestAttemptContent.sound = UNNotificationSound.criticalSoundNamed(UNNotificationSoundName(rawValue: sound), withAudioVolume: audioVolume)
        } else {
            bestAttemptContent.sound = UNNotificationSound.defaultCriticalSound(withAudioVolume: audioVolume)
        }
    }
}

extension UNMutableNotificationContent {
    /// 是否是重要警告
    var isCritical: Bool {
        self.userInfo["level"] as? String == "critical"
    }

    /// 声音名称
    var soundName: String? {
        (self.userInfo["aps"] as? [AnyHashable: Any])?["sound"] as? String
    }
}
