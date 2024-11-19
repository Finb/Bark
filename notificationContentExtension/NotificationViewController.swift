//
//  NotificationViewController.swift
//  NotificationContentExtension
//
//  Created by huangfeng on 2018/7/4.
//  Copyright © 2018 Fin. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {
    let noticeLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(named: "notification_copy_color")
        label.font = UIFont.preferredFont(ofSize: 16)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.noticeLabel)
        self.preferredContentSize = CGSize(width: 0, height: 1)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.preferredContentSize = CGSize(width: 0, height: 1)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.preferredContentSize = CGSize(width: 0, height: 1)
    }

    func didReceive(_ notification: UNNotification) {
        guard notification.request.content.userInfo["autocopy"] as? String == "1"
            || notification.request.content.userInfo["automaticallycopy"] as? String == "1"
        else {
            return
        }
        if let copy = notification.request.content.userInfo["copy"] as? String {
            UIPasteboard.general.string = copy
        } else {
            UIPasteboard.general.string = notification.request.content.body
        }
		
		// 如果是长提醒，关闭铃声
		if notification.request.content.userInfo["call"] as? String == "1"{
			CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFNotificationName(kStopCallProcessorKey as CFString), nil, nil, true)
		}
		
    }

    func didReceive(_ response: UNNotificationResponse, completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void) {
        switch response.actionIdentifier {
        case "copy":
            self.copyAction(response, completionHandler: completion)
        case "mute":
            self.muteAction(response, completionHandler: completion)
        default:
            completion(.dismiss)
        }
    }
    
    /// 复制
    func copyAction(_ response: UNNotificationResponse, completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void) {
        let userInfo = response.notification.request.content.userInfo

        if let copy = userInfo["copy"] as? String {
            UIPasteboard.general.string = copy
        } else {
            UIPasteboard.general.string = response.notification.request.content.body
        }

        showTips(text: NSLocalizedString("Copy", comment: ""))
        completion(.doNotDismiss)
    }
        
    /// 静音分组
    func muteAction(_ response: UNNotificationResponse, completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void) {
        let groupName = response.notification.request.content.threadIdentifier
        // 静音一小时
        GroupMuteSettingManager().settings[groupName] = Date() + 60 * 60
         
        showTips(text: String(format: NSLocalizedString("groupMuted", comment: ""), groupName.isEmpty ? "default" : groupName))
        completion(.doNotDismiss)
    }
    
    func showTips(text: String) {
        self.preferredContentSize = CGSize(width: 0, height: 40)
        self.noticeLabel.text = text
        self.noticeLabel.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 40)
    }
}
