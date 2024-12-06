//
//  Message.swift
//  Bark
//
//  Created by huangfeng on 2020/5/25.
//  Copyright © 2020 Fin. All rights reserved.
//

//import IceCream
import RealmSwift
import UIKit
class Message: Object {
    @objc dynamic var id = NSUUID().uuidString
    @objc dynamic var title: String?
    @objc dynamic var body: String?
    @objc dynamic var url: String?
    @objc dynamic var group: String?
    @objc dynamic var createDate: Date?
    @objc dynamic var expiryDate: Date?

    override class func primaryKey() -> String? {
        return "id"
    }

    override class func indexedProperties() -> [String] {
        return ["group", "createDate"]
    }
}

//extension Message: CKRecordConvertible {}
//extension Message: CKRecordRecoverable {}
