//
//  SimpleEntry.swift
//  WidgetExtension
//
//  Created by huangfeng on 3/25/26.
//  Copyright © 2026 Fin. All rights reserved.
//

import UIKit
import WidgetKit

struct SimpleEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetHistorySnapshot
    let selectedGroup: String?
}

extension WidgetHistorySnapshot {
    static let empty = WidgetHistorySnapshot(messages: [])
    static let placeholder = WidgetHistorySnapshot(messages: [
        WidgetHistoryMessage(id: "1", group: NSLocalizedString("widget.placeholder.group", comment: ""), title: NSLocalizedString("widget.placeholder.title", comment: ""), subtitle: nil, body: NSLocalizedString("widget.placeholder.body", comment: ""), image: nil, createDate: .now.addingTimeInterval(-180)),
        WidgetHistoryMessage(id: "2", group: NSLocalizedString("widget.placeholder.group", comment: ""), title: NSLocalizedString("widget.placeholder.title", comment: ""), subtitle: nil, body: NSLocalizedString("widget.placeholder.body", comment: ""), image: nil, createDate: .now.addingTimeInterval(-180)),
        WidgetHistoryMessage(id: "3", group: NSLocalizedString("widget.placeholder.group", comment: ""), title: NSLocalizedString("widget.placeholder.title", comment: ""), subtitle: nil, body: NSLocalizedString("widget.placeholder.body", comment: ""), image: nil, createDate: .now.addingTimeInterval(-180))
    ])
}
