//
//  DeviceTokenCell.swift
//  Bark
//
//  Created by huangfeng on 2022/3/23.
//  Copyright © 2022 Fin. All rights reserved.
//

import UIKit

class MutableTextCell: BaseTableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: UITableViewCell.CellStyle.value1, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.accessoryType = .none
        self.backgroundColor = BKColor.background.secondary
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func bindViewModel(model: ViewModel) {
        super.bindViewModel(model: model)
        guard let viewModel = model as? MutableTextCellViewModel else {
            return
        }
        self.textLabel?.text = viewModel.title
        viewModel.text
            .drive(self.detailTextLabel!.rx.text)
            .disposed(by: rx.reuseBag)
    }
}
