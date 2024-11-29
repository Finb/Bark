//
//  AddSoundCell.swift
//  Bark
//
//  Created by Fin on 2024/3/29.
//  Copyright © 2024 Fin. All rights reserved.
//

import UIKit

class AddSoundCell: UITableViewCell {
    let button: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("uploadSound"), for: .normal)
        button.setImage(UIImage(named: "music_note-music_note_symbol"), for: .normal)
        button.setTitleColor(BKColor.lightBlue.darken3, for: .normal)
        button.tintColor = BKColor.lightBlue.darken3
        button.titleLabel?.font = UIFont.preferredFont(ofSize: 16)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        // 从 UITableView didSelectRowAt 那响应点击事件
        button.isUserInteractionEnabled = false
        return button
    }()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        contentView.addSubview(button)
        button.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(44)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
