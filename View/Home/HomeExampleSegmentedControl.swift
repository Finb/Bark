//
//  HomeExampleSegmentedControl.swift
//  Bark
//
//  Created by huangfeng on 8/25/26.
//  Copyright © 2026 Fin. All rights reserved.
//

import UIKit

final class HomeExampleSegmentedControl: UIControl {
    private let titles = ["GET", "POST", "JSON"]
    private let selectionFeedback = UISelectionFeedbackGenerator()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 14
        return stackView
    }()

    private lazy var buttons: [UIButton] = titles.map(makeButton)

    var selectedIndex = 0 {
        didSet {
            guard oldValue != selectedIndex else { return }
            updateSelection(animated: window != nil)
            sendActions(for: .valueChanged)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(stackView)
        stackView.frame = bounds
        stackView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        buttons.forEach(stackView.addArrangedSubview)
        updateSelection(animated: false)
        selectionFeedback.prepare()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override var intrinsicContentSize: CGSize {
        var width = stackView.spacing * CGFloat(buttons.count - 1)
        var height: CGFloat = 0
        for button in buttons {
            let size = button.intrinsicContentSize
            width += size.width
            height = max(height, size.height)
        }
        return CGSize(width: ceil(width), height: ceil(height))
    }

    private func makeButton(_ title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.monospacedSystemFont(ofSize: 11, weight: .semibold)
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 2, bottom: 6, right: 2)
        button.addTarget(self, action: #selector(selectExample(_:)), for: .touchUpInside)
        return button
    }

    @objc private func selectExample(_ sender: UIButton) {
        guard let index = buttons.firstIndex(of: sender), selectedIndex != index else { return }
        selectionFeedback.selectionChanged()
        selectionFeedback.prepare()
        selectedIndex = index
    }

    private func updateSelection(animated: Bool) {
        func apply() {
            for (index, button) in buttons.enumerated() {
                let isSelected = index == selectedIndex
                button.setTitleColor(isSelected ? .label : .tertiaryLabel, for: .normal)
                button.accessibilityTraits = isSelected ? [.button, .selected] : .button
            }
        }
        if animated {
            UIView.animate(withDuration: 0.18, animations: apply)
        } else {
            apply()
        }
    }
}
