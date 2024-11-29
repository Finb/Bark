//
//  ImageProcessor.swift
//  NotificationServiceExtension
//
//  Created by huangfeng on 2024/5/29.
//  Copyright © 2024 Fin. All rights reserved.
//

import Foundation
import MobileCoreServices

class ImageProcessor: NotificationContentProcessor {
    func process(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
        let userInfo = bestAttemptContent.userInfo
        guard let imageUrl = userInfo["image"] as? String,
              let imageFileUrl = await ImageDownloader.downloadImage(imageUrl)
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
}
