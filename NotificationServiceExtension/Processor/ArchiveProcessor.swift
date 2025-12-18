//
//  ArchiveProcessor.swift
//  NotificationServiceExtension
//
//  Created by huangfeng on 2024/5/29.
//  Copyright © 2024 Fin. All rights reserved.
//

import Foundation

class ArchiveProcessor: NotificationContentProcessor {
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
            let markdown = userInfo["markdown"] as? String

            // 准备消息数据字典
            var messageDict: [String: Any] = [:]
            
            let messageId = (id != nil && !id!.isEmpty) ? id! : UUID().uuidString
            messageDict["id"] = messageId
            
            if let title = title {
                messageDict["title"] = title
            }
            if let subtitle = subtitle {
                messageDict["subtitle"] = subtitle
            }
            if let markdown = markdown, !markdown.isEmpty {
                messageDict["body"] = markdown
                messageDict["bodyType"] = "markdown"
            } else if let body = body {
                messageDict["body"] = body
            }
            if let url = url {
                messageDict["url"] = url
            }
            if let image = image {
                messageDict["image"] = image
            }
            if let group = group {
                messageDict["group"] = group
            }
            messageDict["createDate"] = Date().timeIntervalSince1970
            
            // 写入 plist 文件
            if let groupUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.bark") {
                let pendingMessagesDir = groupUrl.appendingPathComponent("pending_messages")
                
                // 创建目录（如果不存在）
                try? FileManager.default.createDirectory(at: pendingMessagesDir, withIntermediateDirectories: true, attributes: nil)
                
                let plistUrl = pendingMessagesDir.appendingPathComponent("\(messageId).plist")
                let dict = NSDictionary(dictionary: messageDict)
                dict.write(to: plistUrl, atomically: true)
            }
        }
        return bestAttemptContent
    }
}
