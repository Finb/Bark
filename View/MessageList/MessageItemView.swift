//
//  MessageItemView.swift
//  Bark
//
//  Created by huangfeng on 12/23/24.
//  Copyright © 2024 Fin. All rights reserved.
//

import ImageViewer_swift
import Kingfisher
import Photos
import SVProgressHUD
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
        imageView.contentMode = .scaleAspectFit
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
    
    var tapAction: ((_ message: MessageItemModel, _ sourceView: MessageItemView) -> Void)?
    
    static var imageCache: ImageCache?
    static var imageCacheCreatedTime: Date?
    /// 用于查找通知扩展缓存的图片
    
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
    /// 获取图片缓存，用于查找由通知扩展缓存的图片
    /// - Note: 如果创建的图片缓存时间点在传入 date 之前，则需要重新创建图片缓存。因为 Kingfisher/DiskStorage 会在创建时，使用 maybeCached Set 缓存图片路径。
    /// 由于 Bark 会在 NotificationServiceExtension 使用新的 ImageCache 示例缓存图片， 导致新缓存的图片没有更新到主 APP 的 ImageCache 实例中的 maybeCached，于是被误认为没有缓存导致问题
    /// - Parameter date: 图片缓存有效时间点
    /// - Returns: 图片缓存
    func getImageCache(date: Date) -> ImageCache {
        if let cache = MessageItemView.imageCache, let createdTime = MessageItemView.imageCacheCreatedTime, createdTime > date {
            return cache
        }
        let groupUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.bark")
        let cache = try? ImageCache(name: "shared", cacheDirectoryURL: groupUrl)
        MessageItemView.imageCache = cache
        MessageItemView.imageCacheCreatedTime = Date()
        return cache ?? ImageCache.default
    }

    func setMessage(message: MessageItemModel) {
        self.bodyLabel.attributedText = message.attributedText
        self.dateLabel.text = message.dateText
        if let image = message.image {
            imageView.isHidden = false
            // 图片未缓存时，使用的默认尺寸
            remakeImageViewConstraints(width: 200, height: 100)
            // 移除图片查看器
            imageView.removeImageViewer()
            
            // loadDiskFileSynchronously
            imageView.kf.setImage(with: URL(string: image), options: [.targetCache(getImageCache(date: message.createDate ?? Date())), .keepCurrentImageWhileLoading, .loadDiskFileSynchronously]) { [weak self] result in
                guard let self else { return }
                guard let image = try? result.get().image else {
                    self.imageView.image = nil
                    return
                }
                
                // 获取系统是否是夜间模式
                let isDarkMode = UIScreen.main.traitCollection.userInterfaceStyle == .dark
                var options: [ImageViewerOption] = [
                    .closeIcon(UIImage(named: "back")!),
                    .theme(isDarkMode ? .dark : .light),
                    .contentMode(.scaleAspectFit)
                ]
                if #available(iOS 14.0, *) {
                    options.append(.rightNavItemTitle(NSLocalizedString("save"), onTap: { [weak self] _ in
                        // 保存 image 到相册
                        self?.saveImageToAlbum(image)
                    }))
                }
                self.imageView.setupImageViewer(options: options)
                
                layoutImageView(image: image)
            }
        } else {
            imageView.isHidden = true
            remakeImageViewConstraints(width: 0, height: 0)
        }
    }
    
    func layoutImageView(image: UIImage) {
        let scale = image.size.height / image.size.width
        // iPad 下，图片宽度不超过 500。如果图片尺寸小于控件宽度，则以实际图片尺寸作为宽度
        var width = min(min(500, UIScreen.main.bounds.width - 32 - 24), image.width)
        var height = width * scale
        
        if height > 400 {
            width = 400 / scale
            height = 400
        }
        
        remakeImageViewConstraints(width: width, height: height)
    }
    
    func remakeImageViewConstraints(width: CGFloat, height: CGFloat) {
        imageView.snp.remakeConstraints { make in
            make.width.equalTo(width)
            make.height.equalTo(height)
        }
    }
}

@available(iOS 14.0, *)
extension MessageItemView {
    func saveImageToAlbum(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    SVProgressHUD.showInfo(withStatus: NSLocalizedString("noPermission"))
                }
                return
            }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                DispatchQueue.main.async {
                    if success {
                        SVProgressHUD.showSuccess(withStatus: NSLocalizedString("saveSuccess"))
                    } else {
                        SVProgressHUD.showError(withStatus: error?.localizedDescription)
                    }
                }
            }
        }
    }
}

extension UIImageView {
    func removeImageViewer() {
        var _tapRecognizer: UIGestureRecognizer?
        gestureRecognizers?.forEach {
            // 手势类名是 TapWithDataRecognizer
            if "\(type(of: $0))" == "TapWithDataRecognizer" {
                _tapRecognizer = $0
            }
        }
        if let _tapRecognizer {
            self.removeGestureRecognizer(_tapRecognizer)
        }
    }
}
