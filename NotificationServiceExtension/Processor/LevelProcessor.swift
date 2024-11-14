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
		
		
        
        // 重要警告
        if level == "critical" {
            // 默认音量
            var audioVolume: Float = 0.5
            // 指定音量，取值范围是 1 - 10 , 会转换成 0.1 - 1
            if let volume = bestAttemptContent.userInfo["volume"] as? String, let volume = Float(volume) {
                audioVolume = max(0.1, min(1, volume / 10.0))
            }
            // 设置重要警告 sound
            if let sound = bestAttemptContent.soundName {
                bestAttemptContent.sound = UNNotificationSound.criticalSoundNamed(UNNotificationSoundName(rawValue: sound), withAudioVolume: audioVolume)
            } else {
                bestAttemptContent.sound = UNNotificationSound.defaultCriticalSound(withAudioVolume: audioVolume)
            }
            return bestAttemptContent
        }
		
		
		// MARK: - 增加调用的便捷性，level直接传入数字，按照数字逻辑处理通知级别和音量大小
		/// 小于0 :  小于0的都视为active
		/// 等于0 : passive
		/// 等于1 : timeSensitive
		/// 大于1:  critical  大于1的都视为 "critical" 情况
		if let levelNumber = Int(level){
			/// 如果小于0 视为默认 active
			guard levelNumber >= 0 else { return bestAttemptContent }
			
			switch levelNumber{
			case 0:
				if #available(iOSApplicationExtension 15.0, *) {
					bestAttemptContent.interruptionLevel = UNNotificationInterruptionLevel.passive
				}
			case 1:
				if #available(iOSApplicationExtension 15.0, *) {
					bestAttemptContent.interruptionLevel = UNNotificationInterruptionLevel.timeSensitive
				}
			default:
				
				/// 指定音量，取值范围是 1 - 10 , 会转换成 0.1 - 1
				var audioVolume = max(0.1, min(1, Float(levelNumber) / 10.0))
				/// 设置重要警告 sound
				if let sound = bestAttemptContent.soundName {
					bestAttemptContent.sound = UNNotificationSound.criticalSoundNamed(UNNotificationSoundName(rawValue: sound), withAudioVolume: audioVolume)
				} else {
					bestAttemptContent.sound = UNNotificationSound.defaultCriticalSound(withAudioVolume: audioVolume)
				}
			}
			
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
