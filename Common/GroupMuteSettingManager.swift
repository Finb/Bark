//
//  GroupMuteSettingManager.swift
//  Bark
//
//  Created by huangfeng on 11/6/24.
//  Copyright © 2024 Fin. All rights reserved.
//

import UIKit

let kGroupMuteSettingKey = "groupMuteSettings"

/// 保存各分组的静音截止时间，注意 NotificationServiceExtension 和 NotificationContentExtension 是不同进程，不共享单例的（别用单例）
class GroupMuteSettingManager: NSObject {
    let defaults = UserDefaults(suiteName: "group.bark")
    
    var settings: [String: Date] = [:] {
        didSet {
            defaults?.set(settings, forKey: kGroupMuteSettingKey)
        }
    }

    override init() {
        super.init()
        if let settings = defaults?.dictionary(forKey: kGroupMuteSettingKey) as? [String: Date] {
            self.settings = settings
        }
        // 清理过期的设置
        for setting in settings {
            if setting.value < Date() {
                self.settings.removeValue(forKey: setting.key)
            }
        }
    }
}
