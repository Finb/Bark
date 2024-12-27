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
    case message(model: MessageItemModel)
    /// 一组消息，可以收缩折叠
    case messageGroup(name: String, totalCount: Int, messages: [MessageItemModel])
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.message(let l), .message(let r)):
            return l.id == r.id && l.dateText == r.dateText
        case (.messageGroup(let l, _, let lMessages), .messageGroup(let r, _, let rMessages)):
            if l != r {
                return false
            }
            if lMessages.first?.dateText != rMessages.first?.dateText {
                return false
            }
            for (lMessage, rMessage) in zip(lMessages, rMessages) {
                if lMessage.id != rMessage.id {
                    return false
                }
            }
            return true
        default:
            return false
        }
    }
}

extension MessageListCellItem: IdentifiableType {
    typealias Identity = String
    
    var identity: String {
        switch self {
        case .message(let model):
            return "list_\(model.id)"
        case .messageGroup(_, _, let messages):
            return "group_\(messages.first?.id ?? "")"
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
