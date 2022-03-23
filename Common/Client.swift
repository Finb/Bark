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

    var currentNavigationController: UINavigationController? {
        let controller = UIApplication.shared.delegate?.window??.rootViewController as? BarkSnackbarController
        let nav = (controller?.rootViewController as? UITabBarController)?.selectedViewController as? UINavigationController
        return nav
    }

    var currentTabBarController: StateStorageTabBarController? {
        let controller = UIApplication.shared.delegate?.window??.rootViewController as? BarkSnackbarController
        return controller?.rootViewController as? StateStorageTabBarController
    }
    
    let appVersion: String = {
        var version = "0.0.0"
        if let infoDict = Bundle.main.infoDictionary {
            if let appVersion = infoDict["CFBundleVersion"] as? String {
                version = appVersion
            }
        }
        return version
    }()
    
    private var _key: String?
    var key: String? {
        get {
            if _key == nil, let aKey = Settings[.key] {
                _key = aKey
            }
            return _key
        }
        set {
            _key = newValue
            Settings[.key] = newValue
        }
    }
    
    enum ClienState {
        case ok
        case unRegister
        case serverError
    }
    var deviceToken = BehaviorRelay<String?>(value: nil)
    var state = BehaviorRelay<ClienState>(value: .ok)
    
    var dispose: Disposable?
    func bindDeviceToken() {
        if let token = deviceToken.value, token.count > 0 {
            dispose?.dispose()
            
            dispose = BarkApi.provider
                .request(.register(
                    key: key,
                    devicetoken: token))
                .filterResponseError()
                .map { json -> ClienState in
                    switch json {
                    case .success(let json):
                        if let key = json["data", "key"].rawString() {
                            Client.shared.key = key
                            return .ok
                        }
                        else {
                            return .serverError
                        }
                    case .failure:
                        return .serverError
                    }
                }
                .bind(to: state)
        }
    }
    
    func registerForRemoteNotifications() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge], completionHandler: { (_ granted: Bool, _: Error?) -> Void in
            if granted {
                dispatch_sync_safely_main_queue {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            else {
                print("没有打开推送")
            }
        })
    }
    
    func openUrl(url: URL) {
        if ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
            UIApplication.shared.open(url, options: [UIApplication.OpenExternalURLOptionsKey.universalLinksOnly: true]) { success in
                if !success {
                    // 打不开Universal Link时，则用内置 safari 打开
                    self.currentNavigationController?.present(BarkSFSafariViewController(url: url), animated: true, completion: nil)
                }
            }
        }
        else {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
