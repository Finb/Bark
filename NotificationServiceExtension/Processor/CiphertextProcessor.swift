//
//  CiphertextProcessor.swift
//  NotificationServiceExtension
//
//  Created by huangfeng on 2024/5/29.
//  Copyright © 2024 Fin. All rights reserved.
//

import Foundation
import SwiftyJSON

/// 加密推送
class CiphertextProcessor: NotificationContentProcessor {
    func process(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
        var userInfo = bestAttemptContent.userInfo
        guard let ciphertext = userInfo["ciphertext"] as? String else {
            return bestAttemptContent
        }
        
        // 如果是加密推送，则使用密文配置 bestAttemptContent
        do {
            var map = try decrypt(ciphertext: ciphertext, iv: userInfo["iv"] as? String)
            
            var alert = [String: Any]()
            var soundName: String? = nil
            if let title = map["title"] as? String {
                bestAttemptContent.title = title
                alert["title"] = title
            }
            if let subtitle = map["subtitle"] as? String {
                bestAttemptContent.subtitle = subtitle
                alert["subtitle"] = subtitle
            }
            if let body = map["body"] as? String {
                bestAttemptContent.body = body
                alert["body"] = body
            }
            if let group = map["group"] as? String {
                bestAttemptContent.threadIdentifier = group
            }
            if var sound = map["sound"] as? String {
                if !sound.hasSuffix(".caf") {
                    sound = "\(sound).caf"
                }
                soundName = sound
                bestAttemptContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: sound))
            }
            if let badge = map["badge"] as? String, let badgeValue = Int(badge) {
                bestAttemptContent.badge = badgeValue as NSNumber
            }
            var aps: [String: Any] = ["alert": alert]
            if let soundName {
                aps["sound"] = soundName
            }
            map["aps"] = aps
        
            userInfo = map
            bestAttemptContent.userInfo = userInfo
            return bestAttemptContent
        } catch {
            bestAttemptContent.body = "Decryption Failed"
            bestAttemptContent.userInfo = ["aps": ["alert": ["body": bestAttemptContent.body]]]
            throw NotificationContentProcessorError.error(content: bestAttemptContent)
        }
    }
    
    /// 解密文本
    /// - Parameters:
    ///   - ciphertext: 密文
    ///   - iv: iv 如果不传就用配置保存的，传了就以传的 iv 为准
    /// - Returns: 解密后的 json 数据
    private func decrypt(ciphertext: String, iv: String? = nil) throws -> [AnyHashable: Any] {
        guard var fields = CryptoSettingManager.shared.fields else {
            throw "No encryption key set"
        }
        if let iv = iv {
            // Support using specified IV parameter for decryption
            fields.iv = iv
        }
        
        let aes = try AESCryptoModel(cryptoFields: fields)
        
        let json = try aes.decrypt(ciphertext: ciphertext)
        
        guard let data = json.data(using: .utf8), let map = JSON(data).dictionaryObject else {
            throw "JSON parsing failed"
        }
        
        var result: [AnyHashable: Any] = [:]
        for (key, val) in map {
            // 将key重写为小写, 防止用户误输入大小写，全按小写处理
            let key = key.lowercased()
            // 将 value 全部转换成字符串，因为其他方式传参的结果都是字符串
            var val = val
            
            // 如果是数字，转成字符串
            if let num = val as? NSNumber {
                val = num.stringValue
            }
            
            result[key] = val
        }
        return result
    }
}
