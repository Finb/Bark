//
//  HomeFlatButton.swift
//  Bark
//
//  Created by huangfeng on 9/18/26.
//  Copyright © 2026 Fin. All rights reserved.
//

import SnapKit
import UIKit

final class HomeFlatButton: UIControl {
    private let iconView: UIImageView = {
        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFit
        iconView.isHidden = true
        return iconView
    }()
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.isHidden = true
        return label
    }()
    private let stack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 7
        stack.isUserInteractionEnabled = false
        return stack
    }()

    override var tintColor: UIColor! {
        didSet { updateColors() }
    }
    var title: String? {
        didSet {
            titleLabel.text = title
            titleLabel.isHidden = title?.isEmpty ?? true
            accessibilityLabel = title
        }
    }
    var image: UIImage? {
        didSet {
            iconView.image = image
            iconView.isHidden = image == nil
        }
    }

    init() {
        super.init(frame: .zero)

        backgroundColor = BKColor.home.legacyButton
        layer.cornerRadius = 18
        layer.borderWidth = 1 / UIScreen.main.scale
        layer.borderColor = BKColor.home.legacyBorder.cgColor
        clipsToBounds = true

        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(iconView)
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 14, bottom: 12, right: 14))
        }
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(stack.snp.height)
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
        didSet { updateAlpha() }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        layer.borderColor = BKColor.home.legacyBorder.cgColor
    }

    private func updateAlpha() {
        guard isEnabled else {
            alpha = 0.45
            return
        }
        alpha = isHighlighted ? 0.78 : 1
    }

    private func updateColors() {
        iconView.tintColor = tintColor
        titleLabel.textColor = tintColor
    }
}
