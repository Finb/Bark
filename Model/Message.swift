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
    enum BodyType: String {
        case plainText
        case markdown
    }
    @Persisted(primaryKey: true) var id = UUID().uuidString
    @Persisted var title: String?
    @Persisted var subtitle: String?
    @Persisted var body: String?
    @Persisted var bodyType: String?
    @Persisted var url: String?
    @Persisted var image: String?
    @Persisted(indexed: true) var group: String?
    @Persisted(indexed: true) var createDate: Date?

    var type: BodyType {
        get {
            guard let bodyType = bodyType else {
                return .plainText
            }
            return BodyType(rawValue: bodyType) ?? .plainText
        }
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
        self.bodyType = json["bodyType"].string
        self.url = json["url"].string
        self.image = json["image"].string
        self.group = json["group"].string
        self.createDate = Date(timeIntervalSince1970: TimeInterval(createDate))
    }
}
