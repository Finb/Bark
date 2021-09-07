//
//  NotificationService.swift
//  NotificationServiceExtension
//
//  Created by huangfeng on 2018/12/17.
//  Copyright © 2018 Fin. All rights reserved.
//

import UIKit
import UserNotifications
import RealmSwift
import Kingfisher
import MobileCoreServices
class NotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    lazy var realm:Realm? = {
        let groupUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.bark")
        let fileUrl = groupUrl?.appendingPathComponent("bark.realm")
        let config = Realm.Configuration(
            fileURL: fileUrl,
            schemaVersion: 13,
            migrationBlock: { migration, oldSchemaVersion in
                // We haven’t migrated anything yet, so oldSchemaVersion == 0
                if (oldSchemaVersion < 1) {
                    // Nothing to do!
                    // Realm will automatically detect new properties and removed properties
                    // And will update the schema on disk automatically
                }
        })

        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config


        return try? Realm()
    }()
    
    
    /// 自动保存推送
    /// - Parameters:
    ///   - userInfo: 推送参数
    ///   - bestAttemptContentBody: 推送body，如果用户`没有指定要复制的值` ，默认复制 `推送正文`
    fileprivate func autoCopy(_ userInfo: [AnyHashable : Any], defaultCopy  bestAttemptContentBody: String) {
        if userInfo["autocopy"] as? String == "1"
            || userInfo["automaticallycopy"] as? String == "1"{
            if let copy = userInfo["copy"] as? String {
                UIPasteboard.general.string = copy
            }
            else{
                UIPasteboard.general.string = bestAttemptContentBody
            }
        }
    }
    
    
    /// 保存推送
    /// - Parameter userInfo: 推送参数
    /// 如果用户携带了 `isarchive` 参数，则以 `isarchive` 参数值为准
    /// 否则，以用户`应用内设置`为准
    fileprivate func archive(_ userInfo: [AnyHashable : Any]) {
        var isArchive:Bool?
        if let archive = userInfo["isarchive"] as? String{
            isArchive = archive == "1" ? true : false
        }
        if isArchive == nil {
            isArchive = ArchiveSettingManager.shared.isArchive
        }
        let alert = (userInfo["aps"] as? [String:Any])?["alert"] as? [String:Any]
        let title = alert?["title"] as? String
        let body = alert?["body"] as? String
        
        let url = userInfo["url"] as? String
        let group = userInfo["group"] as? String
        
        if (isArchive == true){
            try? realm?.write{
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
    
    
    /// 下载推送图片
    /// - Parameters:
    ///   - userInfo: 推送参数
    ///   - bestAttemptContent: 推送content
    ///   - complection: 下载图片完毕后的回调函数
    fileprivate func downloadImage(_ userInfo: [AnyHashable : Any], content bestAttemptContent: UNMutableNotificationContent, complection: @escaping () -> () ) {
        
        guard let imageUrl = userInfo["image"] as? String,
              let groupUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.bark"),
              let cache = try? ImageCache(name: "shared",cacheDirectoryURL: groupUrl)
        else {
            complection()
            return
        }
        
        // 远程图片
        if imageUrl.hasPrefix("http")
        {
            guard let imageResource = URL(string: imageUrl) else {
                complection()
                return
            }
            
            func finished(){
                let cacheFileUrl = cache.cachePath(forKey: imageResource.cacheKey)
                let copyDestUrl = URL(fileURLWithPath: cacheFileUrl).appendingPathExtension(".tmp")
                // 将图片缓存复制一份，推送使用完后会自动删除，但图片缓存需要留着以后在历史记录里查看
                try? FileManager.default.copyItem(
                    at: URL(fileURLWithPath: cacheFileUrl),
                    to: copyDestUrl)
                
                if  let attachment  = try? UNNotificationAttachment(
                        identifier: "image",
                        url: copyDestUrl,
                        options: [UNNotificationAttachmentOptionsTypeHintKey : kUTTypePNG]){
                    bestAttemptContent.attachments = [ attachment ]
                }
                complection()
            }
            
            
            // 先查看图片缓存
            if cache.diskStorage.isCached(forKey: imageResource.cacheKey) {
                finished()
                return
            }
            
            // 下载图片
            Kingfisher.ImageDownloader.default.downloadImage(with: imageResource, options: nil) { result in
                guard let result = try? result.get() else {
                    complection()
                    return
                }
                // 缓存图片
                cache.storeToDisk(result.originalData, forKey: imageResource.cacheKey, expiration: StorageExpiration.never) { r in
                    finished()
                }
            }
        }
        // 本地图片
        else{
            complection()
        }
    }
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            let userInfo = bestAttemptContent.userInfo
            
            // 自动复制
            autoCopy(userInfo, defaultCopy: bestAttemptContent.body)
            // 保存推送
            archive(userInfo)
            // 下载图片，设置到推送中
            downloadImage(userInfo, content: bestAttemptContent) {
                contentHandler(bestAttemptContent)
            }
        }
        else{
            contentHandler(bestAttemptContent!)
        }
    }
}
