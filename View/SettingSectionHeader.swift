//
//  SettingSectionHeader.swift
//  Bark
//
//  Created by huangfeng on 11/13/24.
//  Copyright © 2024 Fin. All rights reserved.
//

import UIKit

class SettingSectionHeader: UIView {
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = BKColor.grey.darken1
        label.font = UIFont.preferredFont(ofSize: 12)
        label.numberOfLines = 0
        return label
    }()

    init() {
        super.init(frame: CGRect.zero)
        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(12)
            make.bottom.equalTo(-12)
            make.left.equalTo(13)
            make.right.equalTo(-13)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SettingSectionFooter: UIView {
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = BKColor.grey.darken1
        label.font = UIFont.preferredFont(ofSize: 12)
        label.numberOfLines = 0
        return label
    }()

    init() {
        super.init(frame: CGRect.zero)
        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(8)
//            make.bottom.equalTo(-6)
            make.left.equalTo(12)
            make.right.equalTo(-12)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
