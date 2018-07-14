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
//         token = Settings[.deviceToken]
        let token = "ac086ba534f5a51988ebb1be4cbb79f252787801fd451c0b2b561d4468d31d3e"
        if token.count > 0 {
            _ = BarkApi.provider.request(.register(key: key, device_token: token)).filterResponseError().subscribe(onNext: { (json) in
                if let key = json["token"].rawString() {
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
                DispatchQueue.global(qos: .default).async {
                    DispatchQueue.main.sync {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }
            else{
                print("没有打开推送")
            }
        })
    }
}
