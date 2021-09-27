//
//  NotificationDismissSettingManager.swift
//  Bark
//
//  Created by Jiawei Duan on 9/3/21.
//  Copyright © 2021 Fin. All rights reserved.
//

import UIKit

class NotificationDismissSettingManager: NSObject {
    static let shared = NotificationDismissSettingManager()
    let defaults = UserDefaults.init(suiteName: "group.bark")
    var willDismiss: Bool {
        get {
           return defaults?.value(forKey: "willDismiss") as? Bool ?? false
            
        }
        set{
            defaults?.set(newValue, forKey: "willDismiss")
        }
    }
    private override init(){
        super.init()
    }
}
