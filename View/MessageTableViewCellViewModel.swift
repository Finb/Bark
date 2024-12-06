//
//  MessageTableViewCellViewModel.swift
//  Bark
//
//  Created by huangfeng on 2020/11/21.
//  Copyright © 2020 Fin. All rights reserved.
//

import Differentiator
import Foundation
import RxCocoa
import RxDataSources

enum MessageListCellDateStyle {
    /// 相对时间，例如 1分钟前、1小时前
    case relative
    /// 精确时间，例如 2024-01-01 12:00
    case exact
}

class MessageTableViewCellViewModel: ViewModel {
    // 不要在删除消息后，再次使用这个对象，否则会crash
    let message: Message
    var identity: String
    
    let title: BehaviorRelay<String>
    let body: BehaviorRelay<String>
    let url: BehaviorRelay<String>
    
    let date = BehaviorRelay<String>(value: "")
    var dateStyle = BehaviorRelay<MessageListCellDateStyle>(value: .relative)
    
    init(message: Message) {
        self.message = message
        self.identity = message.id
        self.title = BehaviorRelay<String>(value: message.title ?? "")
        self.body = BehaviorRelay<String>(value: message.body ?? "")
        self.url = BehaviorRelay<String>(value: message.url ?? "")

        super.init()
        
        dateStyle.map { style in
            var date: String
            switch style {
            case .relative:
                date = self.message.createDate?.agoFormatString() ?? ""
            case .exact:
                date = self.message.createDate?.formatString(format: "yyyy-MM-dd HH:mm") ?? ""
            }
            if let expiryDate = self.message.expiryDate {
                date += " · \(expiryDate.expiryTimeSinceNow)"
            }
            return date
        }
        .bind(to: date)
        .disposed(by: rx.disposeBag)
    }
}

struct MessageSection {
    var header: String
    var messages: [MessageTableViewCellViewModel]
}

extension MessageSection: AnimatableSectionModelType {
    typealias Item = MessageTableViewCellViewModel
    typealias Identity = String
    
    var items: [MessageTableViewCellViewModel] {
        return self.messages
    }
    
    init(original: MessageSection, items: [MessageTableViewCellViewModel]) {
        self = original
        self.messages = items
    }
    
    var identity: String {
        return header
    }
}

extension MessageTableViewCellViewModel: IdentifiableType {
    typealias Identity = String
    
    override func isEqual(_ object: Any?) -> Bool {
        if let obj = object as? MessageTableViewCellViewModel {
            // 消息列表cell上显示的时间需要随着时间的变化而变化（1分钟前、2分钟前 ...），如果时间不一样的就需要刷新界面
            return self.identity == obj.identity && self.date.value == obj.date.value
        }
        return super.isEqual(object)
    }
}
