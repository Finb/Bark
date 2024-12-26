//
//  MessageTableViewCell.swift
//  Bark
//
//  Created by huangfeng on 2020/5/26.
//  Copyright © 2020 Fin. All rights reserved.
//

import Material
import RxSwift
import SnapKit
import UIKit

/// 单个消息 cell
class MessageTableViewCell: UITableViewCell {
    private let messageView = MessageItemView()
    var message: Message? {
        get {
            return messageView.message
        }
        set {
            messageView.message = newValue
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.contentView.backgroundColor = BKColor.background.primary
        self.contentView.addSubview(messageView)
        messageView.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview()
            make.bottom.equalTo(-10)
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// 群组  cell
class MessageGroupTableViewCell: UITableViewCell {
    /// 方便做动画，实际没什么用
    private let panel: UIView = {
        let panel = UIView()
        panel.backgroundColor = BKColor.background.primary
        return panel
    }()

    /// 消息列表，最多显示 5 条，如果不足5条，多余的会隐藏
    private let messageViews = [
        MessageItemView(isShowShadow: true),
        MessageItemView(isShowShadow: true),
        MessageItemView(isShowShadow: true),
        MessageItemView(isShowShadow: true),
        MessageItemView(isShowShadow: true)
    ]
    
    /// 群组 header ，包含标题、折叠按钮、清除按钮
    private let groupHeader = MessageGroupHeaderView()
    /// 查看更多按钮，消息数小于等于 5 时会隐藏
    private let moreView = MessageGroupMoreView()
    /// 群组 header top offset 约束
    private var groupHeaderTopConstraint: Constraint? = nil

    /// 是否展开
    var isExpanded: Bool = false {
        didSet {
            refreshViewState()
            refreshLayout()
            self.contentView.layoutIfNeeded()
        }
    }
    
    /// 消息列表
    var messages: [Message] = [] {
        didSet {
            for (index, item) in messageViews.enumerated() {
                if index < messages.count {
                    item.message = messages[index]
                    item.isHidden = false
                } else {
                    item.isHidden = true
                }
            }
            refreshLayout()
        }
    }

    /// 剩余消息数量
    var moreCount: Int = 0 {
        didSet {
            moreView.count = moreCount
        }
    }
    
    /// 群组名
    var groupName: String? {
        set {
            if let newValue, !newValue.isEmpty {
                groupHeader.groupName = newValue
            } else {
                groupHeader.groupName = NSLocalizedString("default")
            }
        }
        get {
            return groupHeader.groupName
        }
    }
    
    /// 折叠事件
    var showLessAction: (() -> Void)? {
        get {
            return groupHeader.showLessAction
        }
        set {
            groupHeader.showLessAction = newValue
        }
    }
    
    /// 清除群组事件
    var clearAction: (() -> Void)? {
        get {
            return groupHeader.clearAction
        }
        set {
            groupHeader.clearAction = newValue
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        
        self.contentView.addSubview(panel)
        panel.addSubview(groupHeader)
        panel.addSubview(moreView)
        for view in messageViews.reversed() {
            panel.addSubview(view)
        }

        panel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        groupHeader.snp.remakeConstraints { make in
            groupHeaderTopConstraint = make.top.equalToSuperview().offset(0).constraint
            make.left.equalTo(16)
            make.right.equalTo(-16)
        }
        
        moreView.snp.remakeConstraints { make in
            make.bottom.equalToSuperview().offset(-18)
            make.centerX.equalToSuperview()
        }

        refreshViewState()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 更新UI
    private func refreshViewState() {
        self.messageViews.first?.bodyLabel.isUserInteractionEnabled = isExpanded
        self.contentView.gestureRecognizers?.first?.isEnabled = !isExpanded
        
        for (index, view) in messageViews.enumerated() {
            if isExpanded {
                view.maskAlpha = 0
            } else {
                view.maskAlpha = index == 0 ? 0 : CGFloat(index + 1) * 0.01
            }
        }
    }

    /// 更新布局
    private func refreshLayout() {
        // 调整 header 位置
        groupHeaderTopConstraint?.update(offset: isExpanded ? 0 : 15)
        
        // 最大显示 5 条消息， 也就是 messageViews.count
        let maxCount = min(self.messages.count, self.messageViews.count)
        
        // 清除旧的约束
        for view in messageViews {
            view.snp.removeConstraints()
        }
        
        for (index, item) in messageViews.enumerated() {
            if index >= maxCount {
                break
            }
            
            item.snp.remakeConstraints { make in
                make.left.right.equalToSuperview()
                if isExpanded {
                    if index == 0 {
                        make.top.equalTo(groupHeader.snp.bottom).offset(8)
                    } else {
                        make.top.equalTo(messageViews[index - 1].snp.bottom).offset(8)
                    }
                    if index == maxCount - 1 {
                        if moreCount > 0 {
                            make.bottom.equalTo(moreView.snp.top).offset(-18)
                        } else {
                            make.bottom.equalToSuperview().offset(-18)
                        }
                    }
                    item.transform = .identity
                } else {
                    if index == 0 {
                        make.top.equalToSuperview()
                        item.transform = .identity
                    } else {
                        // 底部边缘最多额外再显示1条消息
                        make.top.equalToSuperview().offset(min(index * 8, 1 * 8))
                        make.height.equalTo(messageViews[0])
                        // 根据 index 逐渐缩小
                        let scale = 1 - CGFloat(index) * 0.04
                        item.transform = CGAffineTransform(scaleX: scale, y: 1)
                    }
                    if index == maxCount - 1 {
                        make.bottom.equalToSuperview().offset(-8)
                    }
                }
            }
        }
    }
}
