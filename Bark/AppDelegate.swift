//
//  AppDelegate.swift
//  Bark
//
//  Created by huangfeng on 2018/3/7.
//  Copyright © 2018年 Fin. All rights reserved.
//

import CloudKit
import CrashReporter
import IQKeyboardManagerSwift
import Material
import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var window: UIWindow?
//    var syncEngine: SyncEngine?
    func setupRealm() {
        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = kRealmDefaultConfiguration

//        // iCloud 同步
//        syncEngine = SyncEngine(objects: [
//            SyncObject(type: Message.self)
//        ], databaseScope: .private)

        #if DEBUG
            let realm = try? Realm()
            print("message count: \(realm?.objects(Message.self).count ?? 0)")
        #endif
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.backgroundColor = UIColor.black
        
        #if !DEBUG
            let config = PLCrashReporterConfig(signalHandlerType: .mach, symbolicationStrategy: [])
            if let crashReporter = PLCrashReporter(configuration: config) {
                // Enable the Crash Reporter.
                do {
                    try crashReporter.enableAndReturnError()
                } catch {
                    print("Warning: Could not enable crash reporter: \(error)")
                }

                if crashReporter.hasPendingCrashReport() {
                    let reportController = CrashReportViewController()
                    do {
                        let data = try crashReporter.loadPendingCrashReportDataAndReturnError()

                        // Retrieving crash reporter data.
                        let report = try PLCrashReport(data: data)

                        if let text = PLCrashReportTextFormatter.stringValue(for: report, with: PLCrashReportTextFormatiOS) {
                            reportController.crashLog = text
                        } else {
                            print("CrashReporter: can't convert report to text")
                        }
                    } catch {
                        print("CrashReporter failed to load and parse with error: \(error)")
                    }

                    // Purge the report.
                    crashReporter.purgePendingCrashReport()
                    self.window?.rootViewController = reportController
                    self.window?.makeKeyAndVisible()
                    return true
                }
            } else {
                print("Could not create an instance of PLCrashReporter")
            }
        #endif
        
        // 必须在应用一开始就配置，否则应用可能提前在配置之前试用了 Realm() ，则会创建两个独立数据库。
        setupRealm()

        IQKeyboardManager.shared.enable = true
        if #available(iOS 14, *), UIDevice.current.userInterfaceIdiom == .pad {
            let splitViewController = BarkSplitViewController(style: .doubleColumn)
            splitViewController.initViewControllers()
            self.window?.rootViewController = BarkSnackbarController(rootViewController: splitViewController)
        } else {
            let tabBarController = StateStorageTabBarController()
            tabBarController.tabBar.tintColor = BKColor.grey.darken4
            
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
        }
        
        // 需先配置好 tabBarController 的 viewControllers，显示时会默认显示上次打开的页面
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

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        notificatonHandler(userInfo: response.notification.request.content.userInfo)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        if UIApplication.shared.applicationState == .active {
            stopCallNotificationProcessor()
        }
        return .alert
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
            alertController.addAction(UIAlertAction(title: NSLocalizedString("CopyContent"), style: .default, handler: { _ in
                if let copy = userInfo["copy"] as? String {
                    UIPasteboard.general.string = copy
                } else {
                    UIPasteboard.general.string = body
                }
            }))
            alertController.addAction(UIAlertAction(title: NSLocalizedString("MoreActions"), style: .default, handler: { _ in
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
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: .cancel, handler: nil))

            navigationController?.present(alertController, animated: true, completion: nil)
        }

        if let presentedController = navigationController?.presentedViewController {
            presentedController.dismiss(animated: false) {
                presentController()
            }
        } else {
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
        // 如果有响铃通知，则关闭响铃
        stopCallNotificationProcessor()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    /// 停止响铃
    func stopCallNotificationProcessor() {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFNotificationName(kStopCallProcessorKey as CFString), nil, nil, true)
    }
}
