//
//  AppDelegate.swift
//  Bark
//
//  Created by huangfeng on 2018/3/7.
//  Copyright © 2018年 Fin. All rights reserved.
//

import CloudKit
import IceCream
import IQKeyboardManagerSwift
import Material
import RealmSwift
import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var window: UIWindow?
    var syncEngine: SyncEngine?
    func setupRealm() {
        let groupUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.bark")
        let fileUrl = groupUrl?.appendingPathComponent("bark.realm")
        let config = Realm.Configuration(
            fileURL: fileUrl,
            schemaVersion: 13,
            migrationBlock: { _, oldSchemaVersion in
                // We haven’t migrated anything yet, so oldSchemaVersion == 0
                if oldSchemaVersion < 1 {
                    // Nothing to do!
                    // Realm will automatically detect new properties and removed properties
                    // And will update the schema on disk automatically
                }
            }
        )
        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config

        // iCloud 同步
        syncEngine = SyncEngine(objects: [
            SyncObject(type: Message.self)
        ], databaseScope: .private)

        #if DEBUG
        let realm = try? Realm()
        print("message count: \(realm?.objects(Message.self).count ?? 0)")
        #endif
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 必须在应用一开始就配置，否则应用可能提前在配置之前试用了 Realm() ，则会创建两个独立数据库。
        setupRealm()

        IQKeyboardManager.shared.enable = true

        self.window = UIWindow(frame: UIScreen.main.bounds)
        let tabBarController = StateStorageTabBarController()
        tabBarController.tabBar.tintColor = BKColor.grey.darken4

        self.window?.backgroundColor = UIColor.black
        self.window?.rootViewController = BarkSnackbarController(
            rootViewController: tabBarController
        )

        tabBarController.viewControllers = [
            BarkNavigationController(rootViewController: HomeViewController(viewModel: HomeViewModel())),
            BarkNavigationController(rootViewController: MessageListViewController(viewModel: MessageListViewModel())),
            BarkNavigationController(rootViewController: MessageSettingsViewController(viewModel: MessageSettingsViewModel()))
        ]

        let tabBarItems = [UITabBarItem(title: NSLocalizedString("service"), image: UIImage(named: "baseline_gite_black_24pt"), tag: 0),
                           UITabBarItem(title: NSLocalizedString("historyMessage"), image: Icon.history, tag: 1),
                           UITabBarItem(title: NSLocalizedString("settings"), image: UIImage(named: "baseline_manage_accounts_black_24pt"), tag: 2)]
        for (index, viewController) in tabBarController.viewControllers!.enumerated() {
            viewController.tabBarItem = tabBarItems[index]
        }

        self.window?.makeKeyAndVisible()

        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().setNotificationCategories([
            UNNotificationCategory(identifier: "myNotificationCategory", actions: [
                UNNotificationAction(identifier: "copy", title: NSLocalizedString("Copy2"), options: UNNotificationActionOptions.foreground)
            ], intentIdentifiers: [], options: .customDismissAction)
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

        return true
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(error)
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceTokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        Client.shared.deviceToken.accept(deviceTokenString)

        // 注册设备
        ServerManager.shared.syncAllServers()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        notificatonHandler(userInfo: notification.request.content.userInfo)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        notificatonHandler(userInfo: response.notification.request.content.userInfo)
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if let dict = userInfo as? [String: NSObject],
           let notification = CKNotification(fromRemoteNotificationDictionary: dict),
           let subscriptionID = notification.subscriptionID, IceCreamSubscription.allIDs.contains(subscriptionID)
        {
            NotificationCenter.default.post(name: Notifications.cloudKitDataDidChangeRemotely.name, object: nil, userInfo: userInfo)
            completionHandler(.newData)
        }
    }

    private func notificatonHandler(userInfo: [AnyHashable: Any]) {
        let navigationController = Client.shared.currentNavigationController
        func presentController() {
            let alert = (userInfo["aps"] as? [String: Any])?["alert"] as? [String: Any]
            let title = alert?["title"] as? String
            let body = alert?["body"] as? String
            let url: URL? = {
                if let url = userInfo["url"] as? String {
                    return URL(string: url)
                }
                return nil
            }()

            // URL 直接打开
            if let url = url {
                Client.shared.openUrl(url: url)
                return
            }

            let alertController = UIAlertController(title: title, message: body, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "复制内容", style: .default, handler: { _ in
                if let copy = userInfo["copy"] as? String {
                    UIPasteboard.general.string = copy
                }
                else {
                    UIPasteboard.general.string = body
                }
            }))
            alertController.addAction(UIAlertAction(title: "更多操作", style: .default, handler: { _ in
                var shareContent = ""
                if let title = title {
                    shareContent += "\(title)\n"
                }
                if let body = body {
                    shareContent += "\(body)\n"
                }
                for (key, value) in userInfo {
                    if ["aps", "title", "body", "url"].contains((key as? String) ?? "") {
                        continue
                    }
                    shareContent += "\(key): \(value) \n"
                }
                var items: [Any] = []
                items.append(shareContent)
                if let url = url {
                    items.append(url)
                }
                let controller = UIApplication.shared.keyWindow?.rootViewController
                let activityController = UIActivityViewController(activityItems: items,
                                                                  applicationActivities: nil)
                controller?.present(activityController, animated: true, completion: nil)
            }))
            alertController.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))

            navigationController?.present(alertController, animated: true, completion: nil)
        }

        if let presentedController = navigationController?.presentedViewController {
            presentedController.dismiss(animated: false) {
                presentController()
            }
        }
        else {
            presentController()
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        ServerManager.shared.syncAllServers()

        // 设置 -1 可以清除应用角标，但不清除通知中心的推送
        // 设置 0 会将通知中心的所有推送一起清空掉
        UIApplication.shared.applicationIconBadgeNumber = -1
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}
