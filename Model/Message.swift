//
//  Message.swift
//  Bark
//
//  Created by huangfeng on 2020/5/25.
//  Copyright © 2020 Fin. All rights reserved.
//

import UIKit
import RealmSwift
import IceCream
class Message: Object {
    @objc dynamic var id = NSUUID().uuidString
    @objc dynamic var title:String?
    @objc dynamic var body:String?
    @objc dynamic var url:String?
    @objc dynamic var createDate:Date?
    
    // 设置为 true 后，将被IceCream自动清理
    @objc dynamic var isDeleted = false
    
    override class func primaryKey() -> String? {
        return "id"
    }
    override class func indexedProperties() -> [String] {
        return ["createDate"]
    }
}

extension Message: CKRecordConvertible {}
extension Message: CKRecordRecoverable {}
