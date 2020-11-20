//
//  SoundCell.swift
//  Bark
//
//  Created by huangfeng on 2020/9/14.
//  Copyright © 2020 Fin. All rights reserved.
//

import UIKit
import Material
import AVKit

class SoundCell: BaseTableViewCell {
    let copyButton = IconButton(image: UIImage(named: "baseline_file_copy_white_24pt"), tintColor: Color.grey.base)
    let nameLabel:UILabel = {
        let label = UILabel()
        label.fontSize = 14
        label.textColor = Color.darkText.primary
        return label
    }()
    let durationLabel:UILabel = {
        let label = UILabel()
        label.fontSize = 12
        label.textColor = Color.darkText.secondary
        return label
    }()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        
        self.contentView.addSubview(nameLabel)
        self.contentView.addSubview(durationLabel)
        self.contentView.addSubview(copyButton)
        
        nameLabel.snp.makeConstraints { (make) in
            make.left.top.equalToSuperview().offset(15)
        }
        durationLabel.snp.makeConstraints { (make) in
            make.left.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(5)
            make.bottom.equalToSuperview().offset(-15)
        }
        copyButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-15)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func bindViewModel(model:ViewModel){
        super.bindViewModel(model: model)
        guard let viewModel = model as? SoundCellViewModel else {
            return
        }
        
        viewModel.name
            .bind(to: nameLabel.rx.text)
            .disposed(by: rx.reuseBag)
        viewModel.duration
            .map { String(format: "%.2f", CMTimeGetSeconds($0) ) }
            .bind(to: durationLabel.rx.text)
            .disposed(by: rx.reuseBag)
        
        copyButton.rx.tap
            .map{ viewModel.name.value }
            .bind(to: viewModel.copyNameAction)
            .disposed(by: rx.reuseBag)
    }
}
