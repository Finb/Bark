//
//  MessageItemView.swift
//  Bark
//
//  Created by huangfeng on 12/23/24.
//  Copyright © 2024 Fin. All rights reserved.
//

import UIKit

enum MessageListCellDateStyle {
    /// 相对时间，例如 1分钟前、1小时前
    case relative
    /// 精确时间，例如 2024-01-01 12:00
    case exact
}

class MessageItemView: UIView {
    let panel: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.backgroundColor = BKColor.background.secondary
        return view
    }()
    
    let blackMaskView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.backgroundColor = UIColor.black
        view.isUserInteractionEnabled = false
        view.alpha = 0
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

    var message: Message? = nil {
        didSet {
            guard let message else {
                return
            }
            setMessage(message: message)
        }
    }

    var dateStyle: MessageListCellDateStyle = .relative {
        didSet {
            guard let message else {
                return
            }
            switch dateStyle {
            case .relative:
                dateLabel.text = message.createDate?.agoFormatString()
            case .exact:
                dateLabel.text = message.createDate?.formatString(format: "yyyy-MM-dd HH:mm")
            }
        }
    }
    
    var maskAlpha: CGFloat = 0 {
        didSet {
            blackMaskView.alpha = maskAlpha
        }
    }
    
    var isShowSubviews: Bool = true {
        didSet {
            for view in [bodyLabel, dateLabel] {
                view.alpha = isShowSubviews ? 1 : 0
            }
        }
    }
    
    init() {
        super.init(frame: .zero)
        self.backgroundColor = BKColor.background.primary
        self.addSubview(panel)
        panel.addSubview(bodyLabel)
        panel.addSubview(dateLabel)
        panel.addSubview(blackMaskView)

        layoutView()
        
        // 切换时间显示样式
        dateLabel.gestureRecognizers?.first?.rx.event.subscribe(onNext: { [weak self] _ in
            guard let self else { return }
            if self.dateStyle != .exact {
                self.dateStyle = .exact
            } else {
                self.dateStyle = .relative
            }
        }).disposed(by: rx.disposeBag)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func layoutView() {
        bodyLabel.snp.makeConstraints { make in
            make.top.equalTo(16)
            make.left.equalTo(12)
            make.right.equalTo(-12)
        }
        dateLabel.snp.makeConstraints { make in
            make.left.equalTo(bodyLabel)
            make.top.equalTo(bodyLabel.snp.bottom).offset(12)
            make.bottom.equalTo(panel).offset(-12).priority(.medium)
        }
        
        panel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        blackMaskView.snp.makeConstraints { make in
            make.edges.equalTo(panel)
        }
    }
}

extension MessageItemView {
    func setMessage(message: Message) {
        let title = message.title ?? ""
        let subtitle = message.subtitle ?? ""
        let body = message.body ?? ""
        let url = message.url ?? ""
        
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
        
        self.dateStyle = .relative
    }
}
