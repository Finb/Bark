//
//  HomeGlassButton.swift
//  Bark
//
//  Created by huangfeng on 8/25/26.
//  Copyright © 2026 Fin. All rights reserved.
//

import UIKit

final class HomeGlassButton: UIControl, UIGestureRecognizerDelegate {
    private let glassView: GlassView = {
        let glassView = GlassView()
        glassView.cornerRadius = 18
        glassView.isInteractive = true
        return glassView
    }()
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
        return stack
    }()

    override var tintColor: UIColor! {
        didSet { updateColors() }
    }
    var glassTintColor: UIColor? {
        didSet { glassView.glassTintColor = glassTintColor?.withAlphaComponent(0.12) }
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
        glassView.legacyBackgroundColor = BKColor.home.legacyButton
        setupGestures()

        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(iconView)
        addSubview(glassView)
        glassView.contentView.addSubview(stack)

        glassView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
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

    private func setupGestures() {
        if #available(iOS 27.0, *) {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            tapGesture.cancelsTouchesInView = false
            tapGesture.delegate = self
            addGestureRecognizer(tapGesture)
        } else {
            // Let UIControl own legacy touch tracking; glass remains interactive on iOS 26+.
            glassView.isUserInteractionEnabled = false
        }
    }

    override var isHighlighted: Bool {
        didSet { updateAlpha() }
    }
    override var isEnabled: Bool {
        didSet { updateAlpha() }
    }

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        if #available(iOS 27.0, *) {
            return false
        }
        return super.beginTracking(touch, with: event)
    }

    private func updateAlpha() {
        guard isEnabled else {
            alpha = 0.45
            return
        }
        if #unavailable(iOS 27.0) {
            glassView.alpha = isHighlighted ? 0.78 : 1
        }
    }

    private func updateColors() {
        iconView.tintColor = tintColor
        titleLabel.textColor = tintColor
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard isEnabled, gesture.state == .ended else { return }
        sendActions(for: .touchUpInside)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}
