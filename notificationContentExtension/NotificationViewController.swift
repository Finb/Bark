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

    let noticeLabel:UILabel = {
        let label = UILabel()
        label.textColor = UIColor.init(named: "notification_copy_color")
        label.text = NSLocalizedString("Copy", comment: "")
        label.font = UIFont.systemFont(ofSize: 16)
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
        || notification.request.content.userInfo["automaticallycopy"] as? String == "1" else {
            return
        }
        if let copy = notification.request.content.userInfo["copy"] as? String
        {
            UIPasteboard.general.string = copy
        }
        else{
            UIPasteboard.general.string = notification.request.content.body
        }
    }
    
    func didReceive(_ response: UNNotificationResponse, completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        
        if let copy = userInfo["copy"] as? String {
            UIPasteboard.general.string = copy
        }
        else{
            UIPasteboard.general.string = response.notification.request.content.body
        }

        self.preferredContentSize = CGSize(width: 0, height: 40)
        self.noticeLabel.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 40)
        
        completion(.doNotDismiss)

    }
}
