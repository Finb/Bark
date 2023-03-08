//
//  NotificationService.swift
//  NotificationServiceExtension
//
//  Created by huangfeng on 2018/12/17.
//  Copyright © 2018 Fin. All rights reserved.
//

import Intents
import Kingfisher
import MobileCoreServices
import RealmSwift
import SwiftyJSON
import UIKit
import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    
    lazy var realm: Realm? = {
        let groupUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.bark")
        let fileUrl = groupUrl?.appendingPathComponent("bark.realm")
        let config = Realm.Configuration(
            fileURL: fileUrl,
            schemaVersion: 13,
            migrationBlock: { _, oldSchemaVersion in
                // We haven’t migrated anything yet, so oldSchemaVersion == 0
                if oldSchemaVersion < 1 {
                    // Nothing to do!
                    // Realm will automatically detect new properties and removed properties
                    // And will update the schema on disk automatically
                }
            }
        )
        
        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config
        return try? Realm()
    }()
    
    /// 自动保存推送
    /// - Parameters:
    ///   - userInfo: 推送参数
    ///   - bestAttemptContentBody: 推送body，如果用户`没有指定要复制的值` ，默认复制 `推送正文`
    fileprivate func autoCopy(_ userInfo: [AnyHashable: Any], defaultCopy: String) {
        if userInfo["autocopy"] as? String == "1"
            || userInfo["automaticallycopy"] as? String == "1"
        {
            if let copy = userInfo["copy"] as? String {
                UIPasteboard.general.string = copy
            }
            else {
                UIPasteboard.general.string = defaultCopy
            }
        }
    }
    
    /// 保存推送
    /// - Parameter userInfo: 推送参数
    /// 如果用户携带了 `isarchive` 参数，则以 `isarchive` 参数值为准
    /// 否则，以用户`应用内设置`为准
    fileprivate func archive(_ userInfo: [AnyHashable: Any]) {
        var isArchive: Bool?
        if let archive = userInfo["isarchive"] as? String {
            isArchive = archive == "1" ? true : false
        }
        if isArchive == nil {
            isArchive = ArchiveSettingManager.shared.isArchive
        }
        let alert = (userInfo["aps"] as? [String: Any])?["alert"] as? [String: Any]
        let title = alert?["title"] as? String
        let body = alert?["body"] as? String
        
        let url = userInfo["url"] as? String
        let group = userInfo["group"] as? String
        
        if isArchive == true {
            try? realm?.write {
                let message = Message()
                message.title = title
                message.body = body
                message.url = url
                message.group = group
                message.createDate = Date()
                realm?.add(message)
            }
        }
    }
    
    /// 保存图片到缓存中
    /// - Parameters:
    ///   - cache: 使用的缓存
    ///   - data: 图片 Data 数据
    ///   - key: 缓存 Key
    func storeImage(cache: ImageCache, data: Data, key: String) async {
        return await withCheckedContinuation { continuation in
            cache.storeToDisk(data, forKey: key, expiration: StorageExpiration.never) { _ in
                continuation.resume()
            }
        }
    }
    
    /// 使用 Kingfisher.ImageDownloader 下载图片
    /// - Parameter url: 下载的图片URL
    /// - Returns: 返回 Result
    func downloadImage(url: URL) async -> Result<ImageLoadingResult, KingfisherError> {
        return await withCheckedContinuation { continuation in
            Kingfisher.ImageDownloader.default.downloadImage(with: url, options: nil) { result in
                continuation.resume(returning: result)
            }
        }
    }
   
    /// 下载推送图片
    /// - Parameter imageUrl: 图片URL字符串
    /// - Returns: 保存在本地中的`图片 File URL`
    fileprivate func downloadImage(_ imageUrl: String) async -> String? {
        guard let groupUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.bark"),
              let cache = try? ImageCache(name: "shared", cacheDirectoryURL: groupUrl),
              let imageResource = URL(string: imageUrl)
        else {
            return nil
        }
        
        // 先查看图片缓存
        if cache.diskStorage.isCached(forKey: imageResource.cacheKey) {
            return cache.cachePath(forKey: imageResource.cacheKey)
        }
        
        // 下载图片
        guard let result = try? await downloadImage(url: imageResource).get() else {
            return nil
        }
        // 缓存图片
        await storeImage(cache: cache, data: result.originalData, key: imageResource.cacheKey)
        
        return cache.cachePath(forKey: imageResource.cacheKey)
    }
    
    /// 为 Notification Content 设置图片
    /// - Parameter bestAttemptContent: 要设置的 Notification Content
    /// - Returns: 返回设置图片后的 Notification Content
    fileprivate func setImage(content bestAttemptContent: UNMutableNotificationContent) async -> UNMutableNotificationContent {
        let userInfo = bestAttemptContent.userInfo
        guard let imageUrl = userInfo["image"] as? String,
              let imageFileUrl = await downloadImage(imageUrl)
        else {
            return bestAttemptContent
        }
        
        let copyDestUrl = URL(fileURLWithPath: imageFileUrl).appendingPathExtension(".tmp")
        // 将图片缓存复制一份，推送使用完后会自动删除，但图片缓存需要留着以后在历史记录里查看
        try? FileManager.default.copyItem(
            at: URL(fileURLWithPath: imageFileUrl),
            to: copyDestUrl
        )
        
        if let attachment = try? UNNotificationAttachment(
            identifier: "image",
            url: copyDestUrl,
            options: [UNNotificationAttachmentOptionsTypeHintKey: kUTTypePNG]
        ) {
            bestAttemptContent.attachments = [attachment]
        }
        return bestAttemptContent
    }
    
    /// 为 Notification Content 设置ICON
    /// - Parameter bestAttemptContent: 要设置的 Notification Content
    /// - Returns: 返回设置ICON后的 Notification Content
    fileprivate func setIcon(content bestAttemptContent: UNMutableNotificationContent) async -> UNMutableNotificationContent {
        if #available(iOSApplicationExtension 15.0, *) {
            
            let userInfo = bestAttemptContent.userInfo
            
            guard let imageUrl = userInfo["icon"] as? String,
                  let imageFileUrl = await downloadImage(imageUrl)
            else {
                return bestAttemptContent
            }
            
            var personNameComponents = PersonNameComponents()
            personNameComponents.nickname = bestAttemptContent.title
            
            let avatar = INImage(imageData: NSData(contentsOfFile: imageFileUrl)! as Data)
            let senderPerson = INPerson(
                personHandle: INPersonHandle(value: "", type: .unknown),
                nameComponents: personNameComponents,
                displayName: personNameComponents.nickname,
                image: avatar,
                contactIdentifier: nil,
                customIdentifier: nil,
                isMe: false,
                suggestionType: .none
            )
            let mePerson = INPerson(
                personHandle: INPersonHandle(value: "", type: .unknown),
                nameComponents: nil,
                displayName: nil,
                image: nil,
                contactIdentifier: nil,
                customIdentifier: nil,
                isMe: true,
                suggestionType: .none
            )
            
            let intent = INSendMessageIntent(
                recipients: [mePerson],
                outgoingMessageType: .outgoingMessageText,
                content: bestAttemptContent.body,
                speakableGroupName: INSpeakableString(spokenPhrase: personNameComponents.nickname ?? ""),
                conversationIdentifier: bestAttemptContent.threadIdentifier,
                serviceName: nil,
                sender: senderPerson,
                attachments: nil
            )
            
            intent.setImage(avatar, forParameterNamed: \.sender)
            
            let interaction = INInteraction(intent: intent, response: nil)
            interaction.direction = .incoming
            
            try? await interaction.donate()
            
            do {
                let content = try bestAttemptContent.updating(from: intent) as! UNMutableNotificationContent
                return content
            }
            catch {}
            
            return bestAttemptContent
        }
        else {
            return bestAttemptContent
        }
    }
    
    func decrypt(ciphertext: String) throws -> [String: Any] {
        guard let fields = CryptoSettingManager.shared.fields else {
            throw "No encryption key set"
        }
        let aes = try AESCryptoModel(cryptoFields: fields)
        
        let json = try aes.decrypt(ciphertext: ciphertext)
        
        guard let data = json.data(using: .utf8), let map = JSON(data).dictionaryObject else {
            throw "JSON parsing failed"
        }
        return map
    }
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> ()) {
        guard let bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent) else {
            contentHandler(request.content)
            return
        }
                
        var userInfo = bestAttemptContent.userInfo
        // 如果是加密推送，则使用密文配置 bestAttemptContent
        if let ciphertext = userInfo["ciphertext"] as? String {
            do {
                var map = try decrypt(ciphertext: ciphertext)
                var alert = [String: Any]()
                if let title = map["title"] as? String {
                    bestAttemptContent.title = title
                    alert["title"] = title
                }
                if let body = map["body"] as? String {
                    bestAttemptContent.body = body
                    alert["body"] = body
                }
                if let sound = map["sound"] as? String {
                    bestAttemptContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: sound))
                }
                if let badge = map["badge"] as? Int {
                    bestAttemptContent.badge = badge as NSNumber
                }
                
                map["aps"] = ["alert": alert]
                userInfo = map
                bestAttemptContent.userInfo = userInfo
            }
            catch {
                bestAttemptContent.body = "Decryption Failed"
                bestAttemptContent.userInfo = ["aps": ["alert": ["body": bestAttemptContent.body]]]
                contentHandler(bestAttemptContent)
                return
            }
        }
           
        // 通知中断级别
        if #available(iOSApplicationExtension 15.0, *) {
            if let level = userInfo["level"] as? String {
                let interruptionLevels: [String: UNNotificationInterruptionLevel] = [
                    "passive": UNNotificationInterruptionLevel.passive,
                    "active": UNNotificationInterruptionLevel.active,
                    "timeSensitive": UNNotificationInterruptionLevel.timeSensitive,
                    "timesensitive": UNNotificationInterruptionLevel.timeSensitive,
                    "critical": UNNotificationInterruptionLevel.critical,
                ]
                bestAttemptContent.interruptionLevel = interruptionLevels[level] ?? .active
            }
        }
        
        // 通知角标
        if let badgeStr = userInfo["badge"] as? String, let badge = Int(badgeStr) {
            bestAttemptContent.badge = NSNumber(value: badge)
        }
        
        // 自动复制
        autoCopy(userInfo, defaultCopy: bestAttemptContent.body)
        
        // 保存推送
        archive(userInfo)
        
        Task.init {
            // 设置推送图标
            let iconResult = await setIcon(content: bestAttemptContent)
            // 设置推送图片
            let imageResult = await self.setImage(content: iconResult)
            contentHandler(imageResult)
        }
    }
}
