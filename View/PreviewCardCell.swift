//
//  PreviewCardCell.swift
//  Bark
//
//  Created by huangfeng on 2018/6/26.
//  Copyright © 2018 Fin. All rights reserved.
//

import Material
import UIKit

class PreviewCardCell: BaseTableViewCell<PreviewCardCellViewModel> {
    let previewButton = IconButton(image: Icon.cm.skipForward, tintColor: BKColor.grey.base)
    let copyButton = IconButton(image: UIImage(named: "baseline_file_copy_white_24pt"), tintColor: BKColor.grey.base)
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(ofSize: 14)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = BKColor.grey.darken3
        label.numberOfLines = 0
        return label
    }()

    let bodyLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(ofSize: 14)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = BKColor.grey.darken2
        label.numberOfLines = 0
        return label
    }()
    
    let noticeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(ofSize: 12)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = BKColor.grey.base
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        return label
    }()

    let contentImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    let card: UIView = {
        let view = UIView()
        view.backgroundColor = BKColor.background.secondary
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        return view
    }()
    
    var copyHandler: (() -> Void)?
    
    let contentLabel: UILabel = {
        let label = UILabel()
        label.lineBreakMode = .byCharWrapping
        label.numberOfLines = 0
        label.font = UIFont.preferredFont(ofSize: 14)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = BKColor.background.primary
        
        contentView.addSubview(card)
        card.addSubview(copyButton)
        card.addSubview(previewButton)
        
        card.snp.makeConstraints { make in
            make.left.top.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview()
        }
        previewButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-10)
            make.centerY.equalTo(card.snp.top).offset(40)
            make.width.height.equalTo(40)
        }
        copyButton.snp.makeConstraints { make in
            make.right.equalTo(previewButton.snp.left).offset(-10)
            make.centerY.equalTo(previewButton)
            make.width.height.equalTo(40)
        }
        
        let titleStackView = UIStackView()
        titleStackView.axis = .vertical
        titleStackView.addArrangedSubview(titleLabel)
        titleStackView.addArrangedSubview(bodyLabel)
        
        card.addSubview(titleStackView)

        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15)
        }
        bodyLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15)
        }
        
        titleStackView.snp.makeConstraints { make in
            make.centerY.equalTo(copyButton)
            make.left.equalToSuperview()
            make.right.equalTo(copyButton.snp.left)
        }

        let contentStackView = UIStackView()
        contentStackView.axis = .vertical
        contentStackView.spacing = 20
        contentStackView.setCustomSpacing(10, after: contentLabel)
        card.addSubview(contentStackView)
        
        contentStackView.addArrangedSubview(contentImageView)
        contentStackView.addArrangedSubview(contentLabel)
        contentStackView.addArrangedSubview(noticeLabel)
        
        contentLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.right.equalToSuperview().offset(-12)
        }
        contentImageView.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
        }
        noticeLabel.snp.makeConstraints { make in
            make.left.equalTo(10)
            make.right.equalTo(-10)
        }
        contentStackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(previewButton.snp.bottom).offset(20)
            make.bottom.equalToSuperview().offset(-10)
        }
        
        noticeLabel.addGestureRecognizer(UITapGestureRecognizer())
    }
    
    override func bindViewModel(model: PreviewCardCellViewModel) {
        super.bindViewModel(model: model)
        
        model.title
            .bind(to: self.titleLabel.rx.text).disposed(by: rx.reuseBag)
        model.body
            .bind(to: self.bodyLabel.rx.text).disposed(by: rx.reuseBag)
        model.content
            .bind(to: self.contentLabel.rx.attributedText).disposed(by: rx.reuseBag)
        model.notice
            .bind(to: self.noticeLabel.rx.attributedText).disposed(by: rx.reuseBag)
        model.contentImage
            .compactMap { $0 }
            .bind(to: self.contentImageView.rx.image)
            .disposed(by: rx.reuseBag)
        model.contentImage
            .map { $0 == nil }
            .bind(to: self.contentImageView.rx.isHidden)
            .disposed(by: rx.reuseBag)
        
        // 点击通知
        noticeLabel.gestureRecognizers!.first!
            .rx.event
            .compactMap { [weak weakModel = viewModel] _ -> ViewModel? in
                // 仅在有 moreViewModel 时 点击
                weakModel?.previewModel.moreViewModel
            }
            .bind(to: model.noticeTap)
            .disposed(by: rx.reuseBag)
        
        // 点击复制
        copyButton.rx.tap.map { [weak self] () -> String in
            self?.contentLabel.text ?? ""
        }
        .bind(to: model.copy)
        .disposed(by: rx.reuseBag)
        
        // 点击预览
        previewButton.rx.tap.compactMap { [weak self] () -> URL? in
            if let urlStr = self?.contentLabel.text?.urlEncoded(),
               let url = URL(string: urlStr)
            {
                return url
            }
            return nil
        }
        .bind(to: model.preview)
        .disposed(by: rx.reuseBag)
    }
}
