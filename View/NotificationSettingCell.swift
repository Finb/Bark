//
//  NotificationSettingCell.swift
//  Bark
//
//  Created by Jiawei Duan on 9/3/21.
//  Copyright © 2021 Fin. All rights reserved.
//

import UIKit

class NotificationSettingCell: BaseTableViewCell {
    let switchButton: UISwitch = {
        let btn = UISwitch()
        return btn
    }()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        
        self.textLabel?.text = NSLocalizedString("defaultNotificationSettings")
        
        contentView.addSubview(switchButton)
        switchButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func bindViewModel(model: ViewModel) {
        super.bindViewModel(model: model)
        guard let viewModel = model as? NotificationSettingCellViewModel else {
            return
        }
        (self.switchButton.rx.isOn <-> viewModel.on)
            .disposed(by: rx.reuseBag)
    }
}

