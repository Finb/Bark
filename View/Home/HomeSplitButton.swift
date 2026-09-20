//
//  HomeSplitButton.swift
//  Bark
//
//  Created by huangfeng on 9/20/26.
//  Copyright © 2026 Fin. All rights reserved.
//

import SnapKit
import UIKit

final class HomeSplitButton: UIControl {
    private enum Metrics {
        static let menuWidth: CGFloat = 40
        static let separatorWidth: CGFloat = 1 / UIScreen.main.scale
        static let titlePadding: CGFloat = 14
    }

    private let separator: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private let menuButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(
            UIImage(systemName: "chevron.down", withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)),
            for: .normal
        )
        button.showsMenuAsPrimaryAction = true
        // 外层是单一无障碍元素，菜单项由 accessibilityCustomActions 暴露
        button.isAccessibilityElement = false
        return button
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .left
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        return label
    }()

    var title: String? {
        didSet {
            titleLabel.text = title
            accessibilityLabel = title
        }
    }
    var menu: UIMenu? {
        didSet { menuButton.menu = menu }
    }

    override var tintColor: UIColor! {
        didSet { updateColors() }
    }

    init() {
        super.init(frame: .zero)

        backgroundColor = BKColor.home.legacyButton
        layer.cornerRadius = 18
        layer.borderWidth = 1 / UIScreen.main.scale
        layer.borderColor = BKColor.home.legacyBorder.cgColor
        clipsToBounds = true

        addSubview(titleLabel)
        addSubview(separator)
        addSubview(menuButton)
        menuButton.snp.makeConstraints { make in
            make.top.bottom.trailing.equalToSuperview()
            make.width.equalTo(Metrics.menuWidth)
        }
        separator.snp.makeConstraints { make in
            make.trailing.equalTo(menuButton.snp.leading)
            make.centerY.equalToSuperview()
            make.width.equalTo(Metrics.separatorWidth)
            make.height.equalToSuperview().inset(12)
        }
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(Metrics.titlePadding)
            make.trailing.lessThanOrEqualTo(separator.snp.leading).offset(-Metrics.titlePadding)
        }

        isAccessibilityElement = true
        accessibilityTraits = .button
        tintColor = .label
        updateColors()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet { updateAlpha() }
    }
    override var isEnabled: Bool {
        didSet {
            menuButton.isEnabled = isEnabled
            updateAlpha()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        layer.borderColor = BKColor.home.legacyBorder.cgColor
    }

    private func updateAlpha() {
        guard isEnabled else {
            alpha = 0.45
            titleLabel.alpha = 1
            return
        }
        alpha = 1
        titleLabel.alpha = isHighlighted ? 0.5 : 1
    }

    private func updateColors() {
        titleLabel.textColor = tintColor
        menuButton.tintColor = tintColor
    }
}
