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

    /// 增加图片view
    let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.noticeLabel)
        self.view.addSubview(self.imageView)
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
        ///  处理图片显示
        self.ImageHandler(notification)

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
            var content = ""
            if !response.notification.request.content.title.isEmpty {
                content += "\(response.notification.request.content.title)\n"
            }
            if !response.notification.request.content.subtitle.isEmpty {
                content += "\(response.notification.request.content.subtitle)\n"
            }
            if !response.notification.request.content.body.isEmpty {
                content += "\(response.notification.request.content.body)\n"
            }
            if let url = userInfo["url"] as? String, !url.isEmpty {
                content += "\(url)\n"
            }
            content = content.trimmingCharacters(in: .whitespacesAndNewlines)
            UIPasteboard.general.string = content
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
        /// 调整页面整个大小为image的高度和label的高度总和
        self.preferredContentSize = CGSize(width: 0, height: self.imageView.frame.height + 40)
        self.noticeLabel.text = text
        /// 调整 y的位置，如果复制内容，显示在图片的底部
        self.noticeLabel.frame = CGRect(x: 0, y: self.imageView.frame.height, width: self.view.bounds.width, height: 40)
    }
}

extension NotificationViewController {
    ///  处理下拉显示大图
    func ImageHandler(_ notification: UNNotification) {
        Task {
            guard let imageUrl = notification.request.content.userInfo["image"] as? String,
                  let imageFileUrl = await ImageDownloader.downloadImage(imageUrl),
                  let image = UIImage(contentsOfFile: imageFileUrl)
            else {
                self.imageView.frame = .zero
                return
            }
            /// 计算图片的比例按照通知界面缩放
            let viewWidth = view.bounds.size.width
            let aspectRatio = image.size.width / image.size.height
            let viewHeight = viewWidth / aspectRatio
            let size = CGSize(width: viewWidth, height: viewHeight)

            DispatchQueue.main.async {
                self.preferredContentSize = size
                self.imageView.image = image
                self.imageView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            }
        }
    }
}
