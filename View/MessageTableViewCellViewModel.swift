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
    let message: Message
    
    let title: BehaviorRelay<String>
    let body: BehaviorRelay<String>
    let url: BehaviorRelay<String>
    
    let date = BehaviorRelay<String>(value: "")
    var dateStyle = BehaviorRelay<MessageListCellDateStyle>(value: .relative)
    
    init(message: Message) {
        self.message = message
        
        self.title = BehaviorRelay<String>(value: message.title ?? "")
        self.body = BehaviorRelay<String>(value: message.body ?? "")
        self.url = BehaviorRelay<String>(value: message.url ?? "")

        super.init()
        
        dateStyle.map { style in
            switch style {
            case .relative:
                return self.message.createDate?.agoFormatString() ?? ""
            case .exact:
                return self.message.createDate?.formatString(format: "yyyy-MM-dd HH:mm") ?? ""
            }
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
    
    var identity: String {
        return "\(self.message.id)"
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let obj = object as? MessageTableViewCellViewModel {
            return self.identity == obj.identity
        }
        return super.isEqual(object)
    }
}
