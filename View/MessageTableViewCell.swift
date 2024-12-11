//
//  MessageTableViewCell.swift
//  Bark
//
//  Created by huangfeng on 2020/5/26.
//  Copyright © 2020 Fin. All rights reserved.
//

import Material
import RxSwift
import UIKit

class MessageTableViewCell: BaseTableViewCell<MessageTableViewCellViewModel> {
    let backgroundPanel: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        view.backgroundColor = BKColor.background.secondary
        return view
    }()
    
    let bodyLabel: UITextView = {
        let label = UITextView()
        label.backgroundColor = UIColor.clear
        label.isEditable = false
        label.dataDetectorTypes = [.phoneNumber, .link]
        label.isScrollEnabled = false
        label.textContainerInset = .zero
        label.textContainer.lineFragmentPadding = 0
        label.font = UIFont.preferredFont(ofSize: 14)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = BKColor.grey.darken4
        return label
    }()
    
    let dateLabel: UILabel = {
        let label = BKLabel()
        label.hitTestSlop = UIEdgeInsets(top: -5, left: -5, bottom: -5, right: -5)
        label.font = UIFont.preferredFont(ofSize: 11, weight: .medium)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = BKColor.grey.base
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer())
        return label
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
        contentView.addSubview(bodyLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(separatorLine)

        layoutView()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func layoutView() {
        bodyLabel.snp.remakeConstraints { make in
            make.top.equalTo(16)
            make.left.equalTo(28)
            make.right.equalTo(-28)
        }
        dateLabel.snp.remakeConstraints { make in
            make.left.equalTo(bodyLabel)
            make.top.equalTo(bodyLabel.snp.bottom).offset(12)
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

        Observable.combineLatest(model.title, model.subtitle, model.body, model.url).subscribe { [weak self] title, subtitle, body, url in
            guard let self else { return }
            
            let text = NSMutableAttributedString(
                string: body,
                attributes: [.font: UIFont.preferredFont(ofSize: 14), .foregroundColor: BKColor.grey.darken4]
            )
            
            if subtitle.count > 0 {
                // 插入一行空行当 spacer
                text.insert(NSAttributedString(
                    string: "\n",
                    attributes: [.font: UIFont.systemFont(ofSize: 6, weight: .medium)]
                ), at: 0)
                
                text.insert(NSAttributedString(
                    string: subtitle + "\n",
                    attributes: [.font: UIFont.preferredFont(ofSize: 16, weight: .medium), .foregroundColor: BKColor.grey.darken4]
                ), at: 0)
            }
            
            if title.count > 0 {
                // 插入一行空行当 spacer
                text.insert(NSAttributedString(
                    string: "\n",
                    attributes: [.font: UIFont.systemFont(ofSize: 6, weight: .medium)]
                ), at: 0)
                
                text.insert(NSAttributedString(
                    string: title + "\n",
                    attributes: [.font: UIFont.preferredFont(ofSize: 16, weight: .medium), .foregroundColor: BKColor.grey.darken4]
                ), at: 0)
            }
            
            if url.count > 0 {
                // 插入一行空行当 spacer
                text.append(NSAttributedString(
                    string: "\n ",
                    attributes: [.font: UIFont.systemFont(ofSize: 8, weight: .medium)]
                ))
                
                text.append(NSAttributedString(string: "\n\(url)", attributes: [
                    .font: UIFont.preferredFont(ofSize: 14),
                    .foregroundColor: BKColor.grey.darken4,
                    .link: url
                ]))
            }
            
            self.bodyLabel.attributedText = text
        }.disposed(by: rx.reuseBag)
        
        model.date.bind(to: self.dateLabel.rx.text).disposed(by: rx.reuseBag)
        
        // 切换时间显示样式
        dateLabel.gestureRecognizers?.first?.rx.event.subscribe(onNext: { _ in
            if model.dateStyle.value != .exact {
                model.dateStyle.accept(.exact)
            } else {
                model.dateStyle.accept(.relative)
            }
        }).disposed(by: rx.reuseBag)
    }
}
