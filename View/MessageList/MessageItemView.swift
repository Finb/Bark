//
//  MessageItemView.swift
//  Bark
//
//  Created by huangfeng on 12/23/24.
//  Copyright © 2024 Fin. All rights reserved.
//

import ImageViewer_swift
import Kingfisher
import UIKit

class MessageItemView: UIView {
    let panel: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.backgroundColor = BKColor.background.secondary
        view.clipsToBounds = true
        return view
    }()
    
    let blackMaskView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.backgroundColor = BKColor.black
        view.isUserInteractionEnabled = false
        view.alpha = 0
        return view
    }()
    
    let bodyLabel: CustomTapTextView = {
        let label = CustomTapTextView()
        label.font = UIFont.preferredFont(ofSize: 14)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = BKColor.grey.darken4
        return label
    }()
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 4
        imageView.clipsToBounds = true
        return imageView
    }()
    
    let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .leading
        return stackView
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

    var message: MessageItemModel? = nil {
        didSet {
            guard let message else {
                return
            }
            setMessage(message: message)
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
    
    var tapAction: ((_ message: MessageItemModel, _ sourceView: UIView) -> Void)?
    
    /// 用于查找通知扩展缓存的图片
    lazy var imageCache: ImageCache = {
        let groupUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.bark")
        let cache = try? ImageCache(name: "shared", cacheDirectoryURL: groupUrl)
        
        return cache ?? KingfisherManager.shared.cache
    }()
    
    init() {
        super.init(frame: .zero)
        self.backgroundColor = BKColor.background.primary
        self.addSubview(panel)
        panel.addSubview(contentStackView)
        panel.addSubview(dateLabel)
        panel.addSubview(blackMaskView)
        contentStackView.addArrangedSubview(bodyLabel)
        contentStackView.addArrangedSubview(imageView)

        layoutView()
        
        // 切换时间显示样式
        dateLabel.gestureRecognizers?.first?.rx.event.subscribe(onNext: { [weak self] _ in
            guard let self else { return }
            if self.message?.dateStyle != .exact {
                self.message?.dateStyle = .exact
            } else {
                self.message?.dateStyle = .relative
            }
            self.dateLabel.text = self.message?.dateText
        }).disposed(by: rx.disposeBag)
        
        self.bodyLabel.customTapAction = { [weak self] in
            guard let self, let message = self.message else { return }
            self.tapAction?(message, self)
        }
        
        panel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap)))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func layoutView() {
        contentStackView.snp.makeConstraints { make in
            make.top.equalTo(16)
            make.left.equalTo(12)
            make.right.equalTo(-12)
        }
        imageView.snp.makeConstraints { make in
            make.width.equalTo(panel).inset(12).priority(.low)
            make.width.lessThanOrEqualTo(500)
            make.height.equalTo(imageView.snp.width).multipliedBy(0.55)
        }
        dateLabel.snp.makeConstraints { make in
            make.left.equalTo(contentStackView)
            make.top.equalTo(contentStackView.snp.bottom).offset(12)
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
    
    @objc func tap() {
        guard let message else { return }
        self.tapAction?(message, self)
    }
}

extension MessageItemView {
    func setMessage(message: MessageItemModel) {
        self.bodyLabel.attributedText = message.attributedText
        self.dateLabel.text = message.dateText
        if let image = message.image {
            imageView.isHidden = false
            // loadDiskFileSynchronously
            imageView.kf.setImage(with: URL(string: image), options: [.targetCache(imageCache), .keepCurrentImageWhileLoading]) { [weak self] _ in
                // 获取系统是否是夜间模式
                let isDarkMode = UIScreen.main.traitCollection.userInterfaceStyle == .dark
                self?.imageView.setupImageViewer(options: [.closeIcon(UIImage(named: "back")!), .theme(isDarkMode ? .dark : .light)])
            }
        } else {
            imageView.isHidden = true
        }
    }
}
