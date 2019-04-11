//
//  NotificationService.swift
//  NotificationServiceExtension
//
//  Created by huangfeng on 2018/12/17.
//  Copyright © 2018 Fin. All rights reserved.
//

import UIKit
import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
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
            contentHandler(bestAttemptContent)
        }
    }
    
}
