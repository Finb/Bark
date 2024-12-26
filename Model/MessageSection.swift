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

enum MessageListCellItem: Equatable {
    /// 单条消息
    case message(model: Message)
    /// 一组消息，可以收缩折叠
    case messageGroup(name: String, totalCount: Int, messages: [Message])
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.message(let l), .message(let r)):
            return l == r
        case (.messageGroup(let l, _, _), .messageGroup(let r, _, _)):
            return l == r
        default:
            return false
        }
    }
}

struct MessageSection {
    var header: String
    var messages: [MessageListCellItem]
}

extension MessageSection: AnimatableSectionModelType {
    typealias Item = MessageListCellItem
    typealias Identity = String
    
    var items: [MessageListCellItem] {
        return self.messages
    }
    
    init(original: MessageSection, items: [MessageListCellItem]) {
        self = original
        self.messages = items
    }
    
    var identity: String {
        return header
    }
}

extension MessageListCellItem: IdentifiableType {
    typealias Identity = String
    
    var identity: String {
        switch self {
        case .message(let model):
            return model.id
        case .messageGroup(_, _, let messages):
            return messages.first?.id ?? ""
        }
    }
}
