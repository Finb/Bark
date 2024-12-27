//
//  MessageItemModel.swift
//  Bark
//
//  Created by huangfeng on 12/27/24.
//  Copyright © 2024 Fin. All rights reserved.
//

import UIKit

enum MessageListCellDateStyle {
    /// 相对时间，例如 1分钟前、1小时前
    case relative
    /// 精确时间，例如 2024-01-01 12:00
    case exact
}

class MessageItemModel {
    var id: String = ""
    var group: String?
    
    var attributedText: NSAttributedString?
    var dateText: String?
    
    var createDate: Date?
    var dateStyle: MessageListCellDateStyle = .relative {
        didSet {
            switch dateStyle {
            case .relative:
                dateText = createDate?.agoFormatString()
            case .exact:
                dateText = createDate?.formatString(format: "yyyy-MM-dd HH:mm")
            }
        }
    }

    init(message: Message) {
        self.id = message.id
        self.group = message.group
        
        let title = message.title ?? ""
        let subtitle = message.subtitle ?? ""
        let body = message.body ?? ""
        let url = message.url ?? ""
        
        let text = NSMutableAttributedString(
            string: body,
            attributes: [.font: UIFont.preferredFont(ofSize: 14), .foregroundColor: BKColor.grey.darken4]
        )
        
        if subtitle.count > 0 {
            // 插入一行空行当 spacer
            text.insert(NSAttributedString(
                string: "\n",
                attributes: [.font: UIFont.systemFont(ofSize: 6, weight: .medium)]
            ), at: 0)
            
            text.insert(NSAttributedString(
                string: subtitle + "\n",
                attributes: [.font: UIFont.preferredFont(ofSize: 16, weight: .medium), .foregroundColor: BKColor.grey.darken4]
            ), at: 0)
        }
        
        if title.count > 0 {
            // 插入一行空行当 spacer
            text.insert(NSAttributedString(
                string: "\n",
                attributes: [.font: UIFont.systemFont(ofSize: 6, weight: .medium)]
            ), at: 0)
            
            text.insert(NSAttributedString(
                string: title + "\n",
                attributes: [.font: UIFont.preferredFont(ofSize: 16, weight: .medium), .foregroundColor: BKColor.grey.darken4]
            ), at: 0)
        }
        
        if url.count > 0 {
            // 插入一行空行当 spacer
            text.append(NSAttributedString(
                string: "\n ",
                attributes: [.font: UIFont.systemFont(ofSize: 8, weight: .medium)]
            ))
            
            text.append(NSAttributedString(string: "\n\(url)", attributes: [
                .font: UIFont.preferredFont(ofSize: 14),
                .foregroundColor: BKColor.grey.darken4,
                .link: url
            ]))
        }
        
        self.attributedText = text
        self.createDate = message.createDate
        defer {
            self.dateStyle = .relative
        }
    }
}
