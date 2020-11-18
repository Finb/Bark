//
//  BarkSettings.swift
//  Bark
//
//  Created by huangfeng on 2018/6/25.
//  Copyright © 2018 Fin. All rights reserved.
//

import UIKit
import DefaultsKit

enum BarkSettingKey:String {
    /// 存放key
    case key = "me.fin.bark.key"
    case servers = "me.fin.bark.servers"
    case currentServer = "me.fin.bark.servers.current"
    
    case deviceToken = "me.fin.bark.deviceToken"
}

class BarkSettings{
    static let shared = BarkSettings()
    private init(){
        
    }
    
    subscript(key:String) -> String? {
        get {
            let storeKey = Key<String>(key)
            return Defaults.shared.get(for: storeKey)
        }
        set {
            let storeKey = Key<String>(key)
            if let value = newValue {
                Defaults.shared.set(value, for: storeKey)
            }
            else {
                Defaults.shared.clear(storeKey)
            }
        }
    }
    
    subscript(key:BarkSettingKey) -> String? {
        get {
            return self[key.rawValue]
        }
        set {
            self[key.rawValue] = newValue
        }
    }
    
    subscript<T : Codable>(key:String) -> T? {
        get {
            let storeKey = Key<T>(key)
            return Defaults.shared.get(for: storeKey)
        }
        set {
            let storeKey = Key<T>(key)
            if let value = newValue {
                Defaults.shared.set(value, for: storeKey)
            }
            else {
                Defaults.shared.clear(storeKey)
            }
        }
    }
    subscript<T : Codable>(key:BarkSettingKey) -> T? {
        get {
            return self[key.rawValue]
        }
        set {
            self[key.rawValue] = newValue
        }
    }
}

let Settings = BarkSettings.shared
