//
//  Client.swift
//  Bark
//
//  Created by huangfeng on 2018/6/25.
//  Copyright © 2018 Fin. All rights reserved.
//

import RxCocoa
import RxSwift
import UIKit
import UserNotifications

class Client: NSObject {
    static let shared = Client()
    override private init() {
        super.init()
    }

    var window: UIWindow? {
        return UIApplication.shared.delegate?.window ?? nil
    }

    var currentSnackbarController: BarkSnackbarController? {
        return self.window?.rootViewController as? BarkSnackbarController
    }

    var currentTabBarController: StateStorageTabBarController? {
        guard let snackbarController = self.currentSnackbarController else {
            return nil
        }
        if #available(iOS 14, *), UIDevice.current.userInterfaceIdiom == .pad {
            return (snackbarController.rootViewController as? BarkSplitViewController)?.compactController
        } else {
            return snackbarController.rootViewController as? BarkTabBarController
        }
    }
    
    enum ClienState {
        case ok
        case unRegister
        case serverError(error: ApiError)
        static func == (lhs: ClienState, rhs: ClienState) -> Bool {
            switch (lhs, rhs) {
            case (.ok, .ok):
                return true
            case (.unRegister, .unRegister):
                return true
            case (.serverError(let error1), .serverError(let error2)):
                return error1.localizedDescription == error2.localizedDescription
            default:
                return false
            }
        }
    }

    var deviceToken = BehaviorRelay<String?>(value: nil)
    var state = BehaviorRelay<ClienState>(value: .ok)
    
    func registerForRemoteNotifications() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert], completionHandler: { (_ granted: Bool, _: Error?) in
            if granted {
                dispatch_sync_safely_main_queue {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("没有打开推送")
            }
        })
    }
    
    func openUrl(url: URL) {
        if ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
            UIApplication.shared.open(url, options: [UIApplication.OpenExternalURLOptionsKey.universalLinksOnly: true]) { success in
                if !success {
                    // 打不开Universal Link时，则用 safari 打开
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
        } else {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
