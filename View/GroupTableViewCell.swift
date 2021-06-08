//
//  GroupTableViewCell.swift
//  Bark
//
//  Created by huangfeng on 2021/6/8.
//  Copyright © 2021 Fin. All rights reserved.
//

import UIKit
import Material

class GroupTableViewCell: BaseTableViewCell {
    let nameLabel:UILabel = {
        let label = UILabel()
        label.fontSize = 14
        label.textColor = Color.darkText.primary
        return label
    }()
    let checkButton: BKButton = {
        let btn = BKButton()
        btn.setImage(UIImage(named: "baseline_radio_button_unchecked_black_24pt"), for: .normal)
        btn.setImage(UIImage(named: "baseline_check_circle_outline_black_24pt"), for: .selected)
        btn.tintColor = Color.lightGray
        btn.hitTestSlop = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        return btn
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        
        self.contentView.addSubview(nameLabel)
        self.contentView.addSubview(checkButton)

        checkButton.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.left.equalToSuperview().offset(15)
            make.centerY.equalToSuperview()
        }
        nameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(checkButton.snp.right).offset(15)
            make.top.equalToSuperview().offset(15)
            make.bottom.equalToSuperview().offset(-15)
        }
        checkButton.rx.tap.subscribe(onNext: {[weak self] in
            (self?.viewModel as? GroupCellViewModel)?.checked.accept(!self!.checkButton.isSelected)
        }).disposed(by: rx.disposeBag)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func bindViewModel(model:ViewModel){
        super.bindViewModel(model: model)
        guard let viewModel = model as? GroupCellViewModel else {
            return
        }
        
        viewModel.name
            .map({ name in
                return name ?? NSLocalizedString("default")
            })
            .bind(to: nameLabel.rx.text)
            .disposed(by: rx.reuseBag)
        
        viewModel.checked
            .bind(to: self.checkButton.rx.isSelected)
            .disposed(by: rx.reuseBag)
        
        viewModel.checked.subscribe(
            onNext: {[weak self] checked in
                self?.checkButton.tintColor = checked ? Color.lightBlue.darken3 : Color.lightGray
            }).disposed(by: rx.reuseBag)
        

    }
}
