//
//  HomeExampleCard.swift
//  Bark
//
//  Created by huangfeng on 8/25/26.
//  Copyright © 2026 Fin. All rights reserved.
//

import UIKit

final class HomeExampleCard: GlassView {
    let segmentedControl = HomeExampleSegmentedControl()
    let copyButton: HomeSplitButton = {
        let button = HomeSplitButton()
        button.title = "Copy2".localized
        button.titleLabel.font = UIFont.preferredFont(forTextStyle: .callout)
        return button
    }()

    let testButton: HomeFlatButton = {
        let button = HomeFlatButton()
        button.title = "sendTest".localized
        button.image = UIImage(systemName: "paperplane.fill")
        button.titleLabel.font = UIFont.preferredFont(forTextStyle: .callout)
        return button
    }()

    private let sectionLabel: UILabel = {
        let label = UILabel()
        label.text = "usageExamples".localized
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        return stack
    }()

    private let languageBadge: UILabel = {
        let label = UILabel()
        label.text = "bash"
        label.font = UIFont.monospacedSystemFont(ofSize: 10, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }()

    private let codeContainer: UIView = {
        let view = UIView()
        view.backgroundColor = BKColor.home.codePanel
        view.layer.cornerRadius = 14
        view.clipsToBounds = true
        return view
    }()
    private let codeLabel: UILabel = {
        let label = UILabel()
        label.font = HomeExampleCard.codeFont
        label.textColor = .label
        label.numberOfLines = 0
        label.lineBreakMode = .byCharWrapping
        return label
    }()

    private var plainCodeText = ""
    private let actions: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.distribution = .fillEqually
        return stack
    }()

    var codeText: String {
        get { plainCodeText }
        set {
            plainCodeText = newValue
            codeLabel.attributedText = CodeHighlighter.highlight(newValue, font: Self.codeFont)
        }
    }

    private static var codeFont: UIFont {
        UIFontMetrics(forTextStyle: .footnote).scaledFont(for: UIFont.monospacedSystemFont(ofSize: 12, weight: .regular))
    }

    override init() {
        super.init()
        codeContainer.addSubview(segmentedControl)
        codeContainer.addSubview(languageBadge)
        codeContainer.addSubview(codeLabel)
        segmentedControl.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.trailing.equalToSuperview().offset(-14)
        }
        languageBadge.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalTo(segmentedControl)
        }
        codeLabel.snp.makeConstraints { make in
            make.top.equalTo(segmentedControl.snp.bottom).offset(6)
            make.leading.trailing.bottom.equalToSuperview().inset(14)
        }

        actions.addArrangedSubview(copyButton)
        actions.addArrangedSubview(testButton)

        stackView.addArrangedSubview(sectionLabel)
        stackView.addArrangedSubview(codeContainer)
        stackView.addArrangedSubview(actions)

        contentView.addSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
        actions.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
