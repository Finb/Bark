//
//  GroupTableViewCell.swift
//  Bark
//
//  Created by huangfeng on 2021/6/8.
//  Copyright © 2021 Fin. All rights reserved.
//

import Material
import UIKit

class GroupTableViewCell: BaseTableViewCell {
    let nameLabel: UILabel = {
        let label = UILabel()
        label.fontSize = 14
        label.textColor = BKColor.grey.darken4
        return label
    }()

    let checkButton: BKButton = {
        let btn = BKButton()
        btn.setImage(UIImage(named: "baseline_radio_button_unchecked_black_24pt"), for: .normal)
        btn.setImage(UIImage(named: "baseline_check_circle_outline_black_24pt"), for: .selected)
        btn.tintColor = BKColor.grey.base
        btn.isUserInteractionEnabled = false
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
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(checkButton.snp.right).offset(15)
            make.top.equalToSuperview().offset(15)
            make.bottom.equalToSuperview().offset(-15)
        }
        let tap = UITapGestureRecognizer()
        self.contentView.addGestureRecognizer(tap)
        tap.rx.event.subscribe(onNext: { [weak self] _ in
            (self?.viewModel as? GroupCellViewModel)?.checked.accept(!self!.checkButton.isSelected)
        }).disposed(by: rx.disposeBag)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func bindViewModel(model: ViewModel) {
        super.bindViewModel(model: model)
        guard let viewModel = model as? GroupCellViewModel else {
            return
        }
        
        viewModel.name
            .map { name in
                name ?? NSLocalizedString("default")
            }
            .bind(to: nameLabel.rx.text)
            .disposed(by: rx.reuseBag)
        
        viewModel.checked
            .bind(to: self.checkButton.rx.isSelected)
            .disposed(by: rx.reuseBag)
        
        viewModel.checked.subscribe(
            onNext: { [weak self] checked in
                self?.checkButton.tintColor = checked ? BKColor.lightBlue.darken3 : BKColor.grey.base
            }).disposed(by: rx.reuseBag)
    }
}
