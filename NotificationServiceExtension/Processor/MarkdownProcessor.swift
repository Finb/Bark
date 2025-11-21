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
        bestAttemptContent.body = MarkdownParser(configuration: config).parse(markdown).string
        return bestAttemptContent
    }
}
