//
//  SpacerCell.swift
//  Bark
//
//  Created by huangfeng on 2021/6/25.
//  Copyright © 2021 Fin. All rights reserved.
//

import UIKit

class SpacerCell: UITableViewCell {
    var height:CGFloat = 0 {
        didSet{
            self.contentView.snp.remakeConstraints { make in
                make.height.equalTo(height)
            }
        }
    }
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.clear
        self.selectionStyle = .none
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
