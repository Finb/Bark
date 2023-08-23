//
//  BKDropDownCellTableViewCell.swift
//  Bark
//
//  Created by huangfeng on 2023/2/9.
//  Copyright © 2023 Fin. All rights reserved.
//

import DropDown
import UIKit

class BKDropDownCell: DropDownCell {

    @IBOutlet var selectBackgroundView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = BKColor.white
        self.selectBackgroundView.layer.cornerRadius = 10
        self.selectBackgroundView.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {

        let executeSelection: () -> Void = { [weak self] in
            guard let `self` = self else { return }

            let selectedBackgroundColor = BKColor.grey.lighten5
            if selected {
                self.selectBackgroundView.backgroundColor = selectedBackgroundColor
                self.optionLabel.textColor = BKColor.grey.darken4
            } else {
                self.selectBackgroundView.backgroundColor = .clear
                self.optionLabel.textColor = BKColor.grey.darken3
            }
        }

        if animated {
            UIView.animate(withDuration: 0.3, animations: {
                executeSelection()
            })
        } else {
            executeSelection()
        }

        accessibilityTraits = selected ? .selected : .none
    }
}
