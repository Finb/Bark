//
//  UNNotificationContent+Extension.swift
//  NotificationContentExtension
//
//  Created by huangfeng on 8/26/25.
//  Copyright © 2025 Fin. All rights reserved.
//

import UIKit

extension UNNotificationContent {
    var bodyText: String {
        guard let aps = self.userInfo["aps"] as? [String: Any],
              let alert = aps["alert"] as? [String: Any],
              let bodyText = alert["body"] as? String
        else {
            return self.body
        }
        return bodyText
    }
}
