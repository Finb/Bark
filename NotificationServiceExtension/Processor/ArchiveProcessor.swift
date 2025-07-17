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
            let subtitle = alert?["subtitle"] as? String
            let body = alert?["body"] as? String
            let url = userInfo["url"] as? String
            let group = userInfo["group"] as? String
            let image = userInfo["image"] as? String
            let id = userInfo["id"] as? String

            try? realm?.write {
                let message = Message()
                if let id, !id.isEmpty {
                    message.id = id
                }
                message.title = title
                message.subtitle = subtitle
                message.body = body
                message.url = url
                message.image = image
                message.group = group
                message.createDate = Date()
                realm?.add(message, update: .all)
            }
        }
        return bestAttemptContent
    }
}
