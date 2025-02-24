//
//  ServerListTableViewCell.swift
//  Bark
//
//  Created by huangfeng on 2022/4/1.
//  Copyright © 2022 Fin. All rights reserved.
//

import Material
import UIKit

class ServerListTableViewCell: BaseTableViewCell<ServerListTableViewCellViewModel> {
    let backgroundPanel: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 3
        view.clipsToBounds = true
        view.backgroundColor = BKColor.background.secondary

        view.clipsToBounds = true
        view.layer.borderColor = BKColor.grey.lighten3.cgColor
        view.layer.borderWidth = 1
        return view
    }()

    let addressLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(ofSize: 14, weight: .medium)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = BKColor.grey.darken4
        label.numberOfLines = 0
        label.lineBreakMode = .byCharWrapping
        return label
    }()

    let keyLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(ofSize: 12)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = BKColor.grey.darken4
        label.numberOfLines = 0
        return label
    }()

    let stateImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 15
        imageView.clipsToBounds = true
        return imageView
    }()

    var state: Bool = false {
        didSet {
            if state {
                stateImageView.image = UIImage(named: "online")
            } else {
                stateImageView.image = UIImage(named: "offline")
            }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = BKColor.background.primary

        addSubview(backgroundPanel)
        addSubview(stateImageView)
        addSubview(addressLabel)
        addSubview(keyLabel)

        backgroundPanel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(18)
            make.right.equalToSuperview().offset(-18)
            make.top.equalToSuperview().offset(5)
            make.bottom.equalToSuperview().offset(-5)
        }

        stateImageView.snp.makeConstraints { make in
            make.centerY.equalTo(backgroundPanel)
            make.left.equalTo(backgroundPanel).offset(13)
            make.width.height.equalTo(30)
        }
        addressLabel.snp.makeConstraints { make in
            make.left.equalTo(stateImageView.snp.right).offset(8)
            make.top.equalTo(backgroundPanel).offset(10)
            make.right.equalTo(backgroundPanel).offset(-18)
        }
        keyLabel.snp.makeConstraints { make in
            make.top.equalTo(addressLabel.snp.bottom).offset(1)
            make.left.right.equalTo(addressLabel)
            make.bottom.equalTo(backgroundPanel).offset(-10)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func bindViewModel(model: ServerListTableViewCellViewModel) {
        super.bindViewModel(model: model)

        model.name
            .bind(to: addressLabel.rx.text)
            .disposed(by: rx.reuseBag)

        model.key
            .bind(to: keyLabel.rx.text)
            .disposed(by: rx.reuseBag)

        model.state
            .subscribe { state in
                self.state = state
            } onError: { _ in }
            .disposed(by: rx.reuseBag)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.backgroundPanel.layer.cornerRadius = self.backgroundPanel.bounds.height / 2
    }
}
