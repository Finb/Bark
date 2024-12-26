//
//  Message.swift
//  Bark
//
//  Created by huangfeng on 2020/5/25.
//  Copyright © 2020 Fin. All rights reserved.
//

import RealmSwift
import UIKit

class Message: Object {
    @objc dynamic var id = NSUUID().uuidString
    @objc dynamic var title: String?
    @objc dynamic var subtitle: String?
    @objc dynamic var body: String?
    @objc dynamic var url: String?
    @objc dynamic var group: String?
    @objc dynamic var createDate: Date?

    override class func primaryKey() -> String? {
        return "id"
    }

    override class func indexedProperties() -> [String] {
        return ["group", "createDate"]
    }
    
    func copyMessage() -> Message {
        let message = Message()
        message.id = self.id
        message.title = self.title
        message.subtitle = self.subtitle
        message.body = self.body
        message.url = self.url
        message.group = self.group
        message.createDate = self.createDate
        return message
    }
}
