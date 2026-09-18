//
//  HomeSettingRow.swift
//  Bark
//
//  Created by huangfeng on 8/25/26.
//  Copyright © 2026 Fin. All rights reserved.
//

import UIKit

final class HomeSettingRow: UIControl {
    private let title: String
    private let symbolName: String
    private let iconTintColor: UIColor
    private let legacyBackgroundColor: UIColor

    private lazy var iconContainer: GlassView = {
        let view = GlassView()
        view.cornerRadius = 8
        view.glassTintColor = iconTintColor.withAlphaComponent(0.2)
        view.legacyBackgroundColor = legacyBackgroundColor
        view.isUserInteractionEnabled = false
        return view
    }()
    private lazy var icon: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: symbolName))
        imageView.tintColor = iconTintColor
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = title
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()
    private let chevron: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        imageView.tintColor = .tertiaryLabel
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    init(title: String, symbolName: String, tintColor: UIColor, legacyBackgroundColor: UIColor) {
        self.title = title
        self.symbolName = symbolName
        self.iconTintColor = tintColor
        self.legacyBackgroundColor = legacyBackgroundColor
        super.init(frame: .zero)

        isAccessibilityElement = true
        accessibilityLabel = title
        accessibilityTraits = .button

        [iconContainer, titleLabel, chevron].forEach(addSubview)
        iconContainer.addSubview(icon)
        iconContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
        }
        icon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(18)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconContainer.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }
        chevron.snp.makeConstraints { make in
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(8)
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet {
            alpha = isHighlighted ? 0.64 : 1
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 44)
    }
}
