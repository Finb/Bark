//
//  MarkdownProcessor.swift
//  NotificationServiceExtension
//
//  Created by huangfeng on 11/21/25.
//  Copyright © 2025 Fin. All rights reserved.
//

import UIKit

class MarkdownProcessor: NotificationContentProcessor {
    func process(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
        let userInfo = bestAttemptContent.userInfo
        guard let markdown = userInfo["markdown"] as? String, !markdown.isEmpty else {
            return bestAttemptContent
        }
        let config = MarkdownParser.Configuration(
            baseFont: UIFont.preferredFont(forTextStyle: .body),
            baseColor: UIColor.white,
            linkColor: UIColor.systemBlue,
            codeTextColor: UIColor.black,
            codeBackgroundColor: UIColor.gray,
            codeBlockTextColor: UIColor.black,
            quoteColor: UIColor.systemGray
        )
        let body = MarkdownParser(configuration: config)
            .parse(markdown)
            .string
            // 将 body 中的多个\n替换为单个\n，避免空行太多内容显示不完整。
            .replacingOccurrences(of: "\n\n+", with: "\n", options: .regularExpression)
        bestAttemptContent.body = body
        return bestAttemptContent
    }
}
