//
//  TextCell.swift
//  Bark
//
//  Created by huangfeng on 2021/6/25.
//  Copyright © 2021 Fin. All rights reserved.
//

import UIKit

class DetailTextCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.accessoryType = .disclosureIndicator
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
