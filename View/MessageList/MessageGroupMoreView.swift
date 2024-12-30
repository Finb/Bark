//
//  MessageGroupMoreView.swift
//  Bark
//
//  Created by huangfeng on 12/25/24.
//  Copyright © 2024 Fin. All rights reserved.
//

import UIKit

class MessageGroupMoreView: UIView {
    private let moreLabel: UILabel = {
        let label = UILabel()
        label.textColor = BKColor.grey.darken3
        label.font = UIFont.preferredFont(ofSize: 12)
        return label
    }()
    
    let arrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "keyboard_arrow_right_symbol")?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = BKColor.grey.darken2
        return imageView
    }()
    
    var count: Int = 0 {
        didSet {
            moreLabel.text = NSLocalizedString("viewAllMessages").format(count)
        }
    }
    
    init() {
        super.init(frame: CGRect.zero)
        self.backgroundColor = BKColor.grey.lighten5
        self.layer.cornerRadius = 28 / 2
        self.clipsToBounds = true
        
        self.addSubview(moreLabel)
        self.addSubview(arrowImageView)
        moreLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(8)
            make.height.equalTo(28).priority(.medium)
            make.top.bottom.equalToSuperview()
        }
        arrowImageView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-6)
            make.centerY.equalToSuperview()
            make.left.equalTo(moreLabel.snp.right).offset(4)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
