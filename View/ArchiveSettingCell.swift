//
//  ArchiveSettingCell.swift
//  Bark
//
//  Created by huangfeng on 2020/5/29.
//  Copyright © 2020 Fin. All rights reserved.
//

import UIKit

class ArchiveSettingCell: UITableViewCell {
    let switchButton: UISwitch = {
        let btn = UISwitch()
        return btn
    }()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        
        self.textLabel?.text = NSLocalizedString("defaultArchiveSettings")
        
        addSubview(switchButton)
        switchButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        
        switchButton.isOn = ArchiveSettingManager.shared.isArchive
        switchButton.addTarget(self, action: #selector(switchToggle(sender:)), for: .valueChanged)
        
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func switchToggle(sender:UISwitch) {
        ArchiveSettingManager.shared.isArchive = sender.isOn
    }

}
