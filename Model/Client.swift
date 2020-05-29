//
//  Client.swift
//  Bark
//
//  Created by huangfeng on 2018/6/25.
//  Copyright © 2018 Fin. All rights reserved.
//

import UIKit
import UserNotifications
class Client: NSObject {
    static let shared = Client()
    private override init() {
        super.init()
    }
    var currentNavigationController:UINavigationController? {
        get {
            let controller = UIApplication.shared.delegate?.window??.rootViewController as? BarkSnackbarController
            let nav = controller?.rootViewController as? UINavigationController
            return nav
        }
    }
    
    let appVersion:String = {
        var version = "0.0.0"
        if let infoDict = Bundle.main.infoDictionary {
            if let appVersion = infoDict["CFBundleVersion"] as? String {
                version = appVersion
            }
        }
        return version
    }()
    
    private var _key:String?
    var key:String? {
        get {
            if _key == nil, let aKey = Settings[.key]{
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
    
    var state = ClienState.ok {
        didSet{
            NotificationCenter.default.post(name: Notification.Name(rawValue: "ClientStateChangeds"), object: nil)
        }
    }
    
    func bindDeviceToken(){
        if let token = Settings[.deviceToken] , token.count > 0{
            _ = BarkApi.provider.request(.register(key: key, devicetoken: token)).filterResponseError().subscribe(onNext: { (json) in
                if let key = json["data","key"].rawString() {
                    Client.shared.key = key
                    self.state = .ok
                }
                else{
                    self.state = .serverError
                }
            }, onError: { (error) in
                self.state = .serverError
            })
        }
    }
    
    func registerForRemoteNotifications() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert , .sound , .badge], completionHandler: {(_ granted: Bool, _ error: Error?) -> Void in
            if granted {
                dispatch_sync_safely_main_queue {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            else{
                print("没有打开推送")
            }
        })
    }
}
