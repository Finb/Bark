//
//  ArchiveSettingCell.swift
//  Bark
//
//  Created by huangfeng on 2020/5/29.
//  Copyright © 2020 Fin. All rights reserved.
//

import UIKit

class ArchiveSettingCell: BaseTableViewCell<ArchiveSettingCellViewModel> {
    let switchButton: UISwitch = {
        let btn = UISwitch()
        return btn
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = BKColor.background.secondary
        self.textLabel?.text = NSLocalizedString("defaultArchiveSettings")

        contentView.addSubview(switchButton)
        switchButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func bindViewModel(model: ArchiveSettingCellViewModel) {
        super.bindViewModel(model: model)
        (self.switchButton.rx.isOn <-> model.on)
            .disposed(by: rx.reuseBag)
    }
}
