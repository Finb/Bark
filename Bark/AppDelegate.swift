//
//  AppDelegate.swift
//  Bark
//
//  Created by huangfeng on 2018/3/7.
//  Copyright © 2018年 Fin. All rights reserved.
//

import IQKeyboardManagerSwift
import IQKeyboardToolbarManager
import SVProgressHUD
import SwiftyStoreKit
import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    private var initialPendingMessagesTask: Task<Void, Never>?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 必须在应用一开始就配置，否则应用可能提前在配置之前试用了 Realm() ，则会创建两个独立数据库。
        setupRealm()
        
        SVProgressHUD.setMinimumDismissTimeInterval(1.5)
        
        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardToolbarManager.shared.isEnabled = true
        // 注册 Darwin Notification 监听
        let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterAddObserver(
            notificationCenter,
            Unmanaged.passUnretained(self).toOpaque(),
            { _, observer, _, _, _ in
                guard let observer = observer else { return }
                let appDelegate = Unmanaged<AppDelegate>.fromOpaque(observer).takeUnretainedValue()
                Task {
                    await appDelegate.processPendingMessages()
                }
            },
            "com.bark.newmessage" as CFString,
            nil,
            .deliverImmediately
        )
        
        // 处理可能在启动前积累的消息
        initialPendingMessagesTask = Task {
            await processPendingMessages()
        }
        
        UNUserNotificationCenter.current().delegate = self
        var actions = [
            UNNotificationAction(identifier: "copy", title: "Copy2".localized, options: UNNotificationActionOptions.foreground)
        ]
        if #available(iOSApplicationExtension 15.0, *) {
            actions.append(UNNotificationAction(identifier: "mute", title: "muteGroup1Hour".localized, options: UNNotificationActionOptions.foreground))
        }
        UNUserNotificationCenter.current().setNotificationCategories([
            // customDismissAction 会在 clear 推送时，调起APP，这时可以顺便更新下 DeviceToken，防止过期。
            UNNotificationCategory(identifier: "myNotificationCategory", actions: actions, intentIdentifiers: [], options: .customDismissAction)
        ])

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            dispatch_sync_safely_main_queue {
                if settings.authorizationStatus == .authorized {
                    Client.shared.registerForRemoteNotifications()
                }
            }
        }

        // 调整返回按钮样式
        let bar = UINavigationBar.appearance(whenContainedInInstancesOf: [BarkNavigationController.self])
        bar.backIndicatorImage = UIImage(named: "back")
        bar.backIndicatorTransitionMaskImage = UIImage(named: "back")
        bar.tintColor = BKColor.grey.darken4

        // 内购
        SwiftyStoreKit.completeTransactions { _ in }
        return true
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(error)
    }

    func waitForInitialPendingMessages() async {
        await initialPendingMessagesTask?.value
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceTokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        Client.shared.deviceToken.accept(deviceTokenString)

        // 注册设备
        ServerManager.shared.syncAllServers()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        defer { completionHandler() }
        guard response.actionIdentifier != UNNotificationDismissActionIdentifier else {
            // clear 推送时，不要弹出提示框
            return
        }
        handleNotification(userInfo: response.notification.request.content.userInfo)
    }
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        guard let delete = userInfo["delete"] as? String, delete == "1", let id = userInfo["id"] as? String else {
            completionHandler(.noData)
            return
        }
        
        // 删除通知中心推送
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [id])

        // 删除历史记录
        Task {
            do {
                try await MessageDeletionCoordinator.delete(ids: [id])
                notifyMessagesDidChange()
                completionHandler(.newData)
            } catch {
                completionHandler(.failed)
            }
        }
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return .alert
    }
    
    func handleNotification(userInfo: [AnyHashable: Any]) {
        let action = userInfo["action"] as? String
        if action == "none" {
            return
        }
        
        // 如果有 URL 直接打开
        if let url = try? (userInfo["url"] as? String)?.asURL() {
            Client.shared.openUrl(url: url)
            return
        }
        
        if action == "alert" {
            alertNotification(userInfo: userInfo)
        }

        // 跳转到消息列表tab
        Client.shared.currentTabPage = .messageHistory
    }

}

extension AppDelegate {
    func alertNotification(userInfo: [AnyHashable: Any]) {
        let alert = (userInfo["aps"] as? [String: Any])?["alert"] as? [String: Any]
        let title = alert?["title"] as? String
        let subtitle = alert?["subtitle"] as? String
        let body = alert?["body"] as? String
        let url = try? (userInfo["url"] as? String)?.asURL()

        let alertController = UIAlertController(title: title, message: body, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "CopyContent".localized, style: .default, handler: { _ in
            if let copy = userInfo["copy"] as? String {
                UIPasteboard.general.string = copy
            } else {
                UIPasteboard.general.string = body
            }
        }))
        alertController.addAction(UIAlertAction(title: "MoreActions".localized, style: .default, handler: { _ in
            var shareContent = ""
            if let title = title {
                shareContent += "\(title)\n"
            }
            if let subtitle = subtitle {
                shareContent += "\(subtitle)\n"
            }
            if let body = body {
                shareContent += "\(body)\n"
            }
            for (key, value) in userInfo {
                if ["aps", "title", "subtitle", "body", "url"].contains((key as? String) ?? "") {
                    continue
                }
                shareContent += "\(key): \(value) \n"
            }
            var items: [Any] = []
            items.append(shareContent)
            if let url = url {
                items.append(url)
            }
            let controller = Client.shared.window?.rootViewController
            let activityController = UIActivityViewController(activityItems: items,
                                                              applicationActivities: nil)
            if let popover = activityController.popoverPresentationController {
                popover.sourceView = controller?.view
                popover.sourceRect = CGRect(x: controller?.view.bounds.midX ?? 0, y: controller?.view.bounds.midY ?? 0, width: 0, height: 0)
            }
            controller?.present(activityController, animated: true, completion: nil)
        }))
        alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))

        let viewController = Client.shared.currentSnackbarController
        
        if let presentedController = viewController?.presentedViewController {
            presentedController.dismiss(animated: false) {
                viewController?.present(alertController, animated: true, completion: nil)
            }
        } else {
            viewController?.present(alertController, animated: true, completion: nil)
        }
    }
}
