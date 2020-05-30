//
//  ArchiveSettingManager.swift
//  Bark
//
//  Created by huangfeng on 2020/5/29.
//  Copyright © 2020 Fin. All rights reserved.
//

import UIKit

class ArchiveSettingManager: NSObject {
    static let shared = ArchiveSettingManager()
    let defaults = UserDefaults.init(suiteName: "group.bark")
    var isArchive: Bool {
        get {
           return defaults?.value(forKey: "isArchive") as? Bool ?? true
            
        }
        set{
            defaults?.set(newValue, forKey: "isArchive")
        }
    }
    private override init(){
        super.init()
    }
}
