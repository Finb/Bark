//
//  WidgetHistoryModels.swift
//  Bark
//
//  Created by OpenCode on 2026/3/26.
//

import Foundation

struct WidgetHistoryMessage: Codable, Identifiable {
    let id: String
    let group: String?
    let title: String?
    let subtitle: String?
    let body: String?
    let image: String?
    let createDate: Date

    init(id: String,
         group: String?,
         title: String?,
         subtitle: String?,
         body: String?,
         image: String?,
         createDate: Date)
    {
        self.id = id
        self.group = group
        self.title = title
        self.subtitle = subtitle
        self.body = body
        self.image = image
        self.createDate = createDate
    }
}

struct WidgetHistorySnapshot: Codable {
    let messages: [WidgetHistoryMessage]
}
