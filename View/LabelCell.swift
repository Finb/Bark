//
//  LabelCell.swift
//  Bark
//
//  Created by huangfeng on 2020/5/29.
//  Copyright © 2020 Fin. All rights reserved.
//

import Material
import UIKit

class LabelCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        self.backgroundColor = BKColor.background.primary
        self.textLabel?.textColor = BKColor.grey.darken1
        self.textLabel?.fontSize = 12
        self.textLabel?.numberOfLines = 0
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
