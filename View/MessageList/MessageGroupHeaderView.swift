//
//  MessageGroupHeaderView.swift
//  Bark
//
//  Created by huangfeng on 12/23/24.
//  Copyright © 2024 Fin. All rights reserved.
//

import UIKit

class MessageGroupHeaderView: UIView {
    private let groupNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(ofSize: 16, weight: .semibold)
        label.textColor = BKColor.grey.darken4
        return label
    }()

    private let showLessAndClearView: ShowLessAndClearView = {
        let view = ShowLessAndClearView()
        return view
    }()
    
    var groupName: String? {
        didSet {
            groupNameLabel.text = groupName
        }
    }

    var showLessAction: (() -> Void)? {
        didSet {
            showLessAndClearView.showLessAction = showLessAction
        }
    }
    
    var clearAction: (() -> Void)? {
        didSet {
            showLessAndClearView.clearAction = clearAction
        }
    }
    
    init() {
        super.init(frame: .zero)
        addSubview(groupNameLabel)
        addSubview(showLessAndClearView)
        
        groupNameLabel.snp.makeConstraints { make in
            make.left.equalTo(8)
            make.top.equalTo(10)
            make.bottom.equalTo(-10)
        }
        showLessAndClearView.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.centerY.equalTo(groupNameLabel)
        }
        
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap)))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func tap() {
        showLessAction?()
    }
}
