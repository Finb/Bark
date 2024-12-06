//
//  ArchiveProcessor.swift
//  NotificationServiceExtension
//
//  Created by huangfeng on 2024/5/29.
//  Copyright © 2024 Fin. All rights reserved.
//

import Foundation
import RealmSwift

class ArchiveProcessor: NotificationContentProcessor {
    private lazy var realm: Realm? = {
        Realm.Configuration.defaultConfiguration = kRealmDefaultConfiguration
        return try? Realm()
    }()
    
    func process(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
        let userInfo = bestAttemptContent.userInfo
        
        var isArchive: Bool = ArchiveSettingManager.shared.isArchive
        if let archive = userInfo["isarchive"] as? String {
            isArchive = archive == "1" ? true : false
        }
        
        if isArchive {
            let alert = (userInfo["aps"] as? [String: Any])?["alert"] as? [String: Any]
            let title = alert?["title"] as? String
            let body = alert?["body"] as? String
            let url = userInfo["url"] as? String
            let group = userInfo["group"] as? String
            let ttl = Double(userInfo["ttl"] as? String ?? "0") ?? 0
            
            try? realm?.write {
                let message = Message()
                message.title = title
                message.body = body
                message.url = url
                message.group = group
                message.createDate = Date()
                if ttl > 0 {
                    message.expiryDate = Date() + TimeInterval(ttl * 60 * 60)
                }
                realm?.add(message)
            }
        }
        return bestAttemptContent
    }
}
