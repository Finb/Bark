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
class NotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    lazy var realm:Realm? = {
        let groupUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.bark")
        let fileUrl = groupUrl?.appendingPathComponent("bark.realm")
        let config = Realm.Configuration(
            fileURL: fileUrl,
            schemaVersion: 12,
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
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            let userInfo = bestAttemptContent.userInfo
            if userInfo["automaticallycopy"] as? String == "1"{
                if let copy = userInfo["copy"] as? String {
                    UIPasteboard.general.string = copy
                }
                else{
                    UIPasteboard.general.string = bestAttemptContent.body
                }
            }

            var isArchive:Bool?
            if let archive = userInfo["isarchive"] as? String{
                isArchive = archive == "1" ? true : false
            }
            if isArchive == nil {
                let defaults = UserDefaults.init(suiteName: "group.bark")
                isArchive = defaults?.bool(forKey: "isArchive") ?? false
            }
            if (isArchive == true){
                try? realm?.write{
                    let message = Message()
                    message.title = userInfo["title"] as? String
                    message.body = userInfo["body"] as? String
                    message.createDate = Date()
                    realm?.add(message)
                }
            }

            contentHandler(bestAttemptContent)
        }
        
        
    }
    
}
