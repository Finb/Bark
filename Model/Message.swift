//
//  Message.swift
//  Bark
//
//  Created by huangfeng on 2020/5/25.
//  Copyright © 2020 Fin. All rights reserved.
//

import RealmSwift
import SwiftyJSON
import UIKit

class Message: Object {
    @objc dynamic var id = NSUUID().uuidString
    @objc dynamic var title: String?
    @objc dynamic var subtitle: String?
    @objc dynamic var body: String?
    @objc dynamic var url: String?
    @objc dynamic var image: String?
    @objc dynamic var group: String?
    @objc dynamic var createDate: Date?

    override class func primaryKey() -> String? {
        return "id"
    }

    override class func indexedProperties() -> [String] {
        return ["group", "createDate"]
    }

    /// 从 JSON 初始化
    convenience init?(json: JSON) {
        self.init()
        guard let id = json["id"].string else {
            return nil
        }
        guard let createDate = json["createDate"].int64 else {
            return nil
        }
        self.id = id
        self.title = json["title"].string
        self.subtitle = json["subtitle"].string
        self.body = json["body"].string
        self.url = json["url"].string
        self.image = json["image"].string
        self.group = json["group"].string
        self.createDate = Date(timeIntervalSince1970: TimeInterval(createDate))
    }
}
