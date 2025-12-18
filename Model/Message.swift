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
    
    convenience init(dict: [String: Any]) {
        self.init()
        if let id = dict["id"] as? String {
            self.id = id
        }
        if let title = dict["title"] as? String {
            self.title = title
        }
        if let subtitle = dict["subtitle"] as? String {
            self.subtitle = subtitle
        }
        if let body = dict["body"] as? String {
            self.body = body
        }
        if let bodyType = dict["bodyType"] as? String {
            self.bodyType = bodyType
        }
        if let url = dict["url"] as? String {
            self.url = url
        }
        if let image = dict["image"] as? String {
            self.image = image
        }
        if let group = dict["group"] as? String {
            self.group = group
        }
        if let createDateInterval = dict["createDate"] as? TimeInterval {
            self.createDate = Date(timeIntervalSince1970: createDateInterval)
        }
    }
}
