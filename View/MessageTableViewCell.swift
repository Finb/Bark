//
//  MessageTableViewCell.swift
//  Bark
//
//  Created by huangfeng on 2020/5/26.
//  Copyright © 2020 Fin. All rights reserved.
//

import Material
import UIKit
class MessageTableViewCell: BaseTableViewCell<MessageTableViewCellViewModel> {
    let backgroundPanel: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 3
        view.clipsToBounds = true
        view.backgroundColor = BKColor.background.secondary
        return view
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = RobotoFont.medium(with: 16)
        label.textColor = BKColor.grey.darken4
        label.numberOfLines = 0
        return label
    }()

    let bodyLabel: GesturePassTextView = {
        let label = GesturePassTextView()
        label.isEditable = false
        label.dataDetectorTypes = [.phoneNumber, .link]
        label.isScrollEnabled = false
        label.textContainerInset = .zero
        label.textContainer.lineFragmentPadding = 0
        label.font = RobotoFont.regular(with: 14)
        label.textColor = BKColor.grey.darken4
        return label
    }()
    
    let urlLabel: UILabel = {
        let label = BKLabel()
        label.hitTestSlop = UIEdgeInsets(top: -20, left: -20, bottom: -20, right: -20)
        label.isUserInteractionEnabled = true
        label.font = RobotoFont.regular(with: 14)
        label.textColor = BKColor.blue.darken1
        label.numberOfLines = 0
        return label
    }()
    
    let dateLabel: UILabel = {
        let label = UILabel()
        label.font = RobotoFont.medium(with: 11)
        label.textColor = BKColor.grey.base
        return label
    }()

    let bodyStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()

    let separatorLine: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = BKColor.background.primary
        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        
        self.backgroundColor = BKColor.background.primary
        contentView.addSubview(backgroundPanel)
        contentView.addSubview(bodyStackView)
        
        bodyStackView.addArrangedSubview(titleLabel)
        bodyStackView.addArrangedSubview(bodyLabel)
        bodyStackView.addArrangedSubview(urlLabel)
        bodyStackView.spacing = 6
        bodyStackView.setCustomSpacing(12, after: bodyLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(separatorLine)
        
        self.urlLabel.addGestureRecognizer(UITapGestureRecognizer())
        
        layoutView()
        self.bodyLabel.superCell = self
        
//        bodyLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap)))
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func layoutView() {
        bodyStackView.snp.makeConstraints { make in
            make.left.top.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }
        titleLabel.snp.remakeConstraints { make in
            make.left.equalTo(12)
            make.right.equalTo(-12)
        }
        bodyLabel.snp.remakeConstraints { make in
            make.left.right.equalTo(titleLabel)
        }
        urlLabel.snp.makeConstraints { make in
            make.left.right.equalTo(bodyLabel)
        }
        dateLabel.snp.remakeConstraints { make in
            make.left.equalTo(bodyLabel)
            make.top.equalTo(bodyStackView.snp.bottom).offset(12)
        }
        separatorLine.snp.remakeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(dateLabel.snp.bottom).offset(12)
            make.height.equalTo(10)
        }
        
        backgroundPanel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalToSuperview()
            make.bottom.equalTo(separatorLine.snp.top)
        }
    }

    override func bindViewModel(model: MessageTableViewCellViewModel) {
        super.bindViewModel(model: model)

        model.title.bind(to: self.titleLabel.rx.text).disposed(by: rx.reuseBag)
        model.body.bind(to: self.bodyLabel.rx.text).disposed(by: rx.reuseBag)
        model.url.bind(to: self.urlLabel.rx.text).disposed(by: rx.reuseBag)
        model.date.bind(to: self.dateLabel.rx.text).disposed(by: rx.reuseBag)
        
        model.title.map { $0.count <= 0 }.bind(to: self.titleLabel.rx.isHidden).disposed(by: rx.reuseBag)
        model.url.map { $0.count <= 0 }.bind(to: self.urlLabel.rx.isHidden).disposed(by: rx.reuseBag)
        
        self.urlLabel.gestureRecognizers?.first?.rx.event
            .map { [weak self] _ in self?.urlLabel.text ?? "" }
            .bind(to: model.urlTap).disposed(by: rx.reuseBag)
    }
}
