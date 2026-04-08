//
//  MessageListSkeletonView.swift
//  Bark
//
//  Created on 2026/4/8.
//  Copyright © 2026 Fin. All rights reserved.
//

import SnapKit
import UIKit

/// 消息列表骨架屏加载视图
final class MessageListSkeletonView: UIView {
    struct CardConfig {
        let titleWidthRatio: CGFloat
        let lineWidthRatios: [CGFloat]
    }

    enum Layout {
        static let cardHorizontalMargin: CGFloat = 16
        static let cardCornerRadius: CGFloat = 10
        static let contentHorizontalPadding: CGFloat = 12
        static let contentTopPadding: CGFloat = 16
        static let contentBottomPadding: CGFloat = 12
        static let titleBarHeight: CGFloat = 16
        static let titleBarCornerRadius: CGFloat = 4
        static let lineBarHeight: CGFloat = 12
        static let lineBarCornerRadius: CGFloat = 3
        static let lineSpacing: CGFloat = 10
        static let titleToLineSpacing: CGFloat = 12
        static let dateBarWidth: CGFloat = 80
        static let dateBarHeight: CGFloat = 10
        static let dateBarCornerRadius: CGFloat = 3
        static let dateTopSpacing: CGFloat = 12
        static let cardSpacing: CGFloat = 10
        static let topInset: CGFloat = 10
        static let bottomInset: CGFloat = 24
    }

    private static let cardConfigs: [CardConfig] = [
        CardConfig(titleWidthRatio: 0.55, lineWidthRatios: [0.90, 0.68, 0.40]),
        CardConfig(titleWidthRatio: 0.42, lineWidthRatios: [0.82, 0.52]),
        CardConfig(titleWidthRatio: 0.65, lineWidthRatios: [0.88, 0.72, 0.55]),
        CardConfig(titleWidthRatio: 0.48, lineWidthRatios: [0.78, 0.45])
    ]

    private let stackView = UIStackView()

    private var placeholderColor: UIColor {
        UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor.white.withAlphaComponent(0.12)
            } else {
                return UIColor.black.withAlphaComponent(0.08)
            }
        }
    }

    init() {
        super.init(frame: .zero)
        backgroundColor = BKColor.background.primary
        isUserInteractionEnabled = false
        setupUI()
        buildCards()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        stackView.axis = .vertical
        stackView.spacing = Layout.cardSpacing
        addSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).offset(Layout.topInset)
            make.left.right.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview().offset(-Layout.bottomInset)
        }
    }

    private func buildCards() {
        for config in Self.cardConfigs {
            stackView.addArrangedSubview(MessageListSkeletonCardView(config: config, placeholderColor: placeholderColor))
        }
    }
}

private final class MessageListSkeletonCardView: UIView {
    private let config: MessageListSkeletonView.CardConfig
    private let placeholderColor: UIColor
    private let panel = UIView()
    private let titleBar = UIView()
    private let dateBar = UIView()
    private lazy var lineBars = config.lineWidthRatios.map { _ in makePlaceholderBar() }

    init(config: MessageListSkeletonView.CardConfig, placeholderColor: UIColor) {
        self.config = config
        self.placeholderColor = placeholderColor
        super.init(frame: .zero)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear

        panel.backgroundColor = BKColor.background.secondary
        panel.layer.cornerRadius = MessageListSkeletonView.Layout.cardCornerRadius
        panel.layer.cornerCurve = .continuous
        panel.clipsToBounds = true
        addSubview(panel)

        panel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(MessageListSkeletonView.Layout.cardHorizontalMargin)
            make.right.equalToSuperview().offset(-MessageListSkeletonView.Layout.cardHorizontalMargin)
            make.top.bottom.equalToSuperview()
        }

        titleBar.backgroundColor = placeholderColor
        titleBar.layer.cornerRadius = MessageListSkeletonView.Layout.titleBarCornerRadius
        titleBar.layer.cornerCurve = .continuous
        panel.addSubview(titleBar)

        titleBar.snp.makeConstraints { make in
            make.top.equalTo(MessageListSkeletonView.Layout.contentTopPadding)
            make.left.equalTo(MessageListSkeletonView.Layout.contentHorizontalPadding)
            make.width.equalToSuperview().multipliedBy(config.titleWidthRatio).offset(-MessageListSkeletonView.Layout.contentHorizontalPadding)
            make.height.equalTo(MessageListSkeletonView.Layout.titleBarHeight)
        }

        var previousBar: UIView = titleBar
        for (index, lineBar) in lineBars.enumerated() {
            panel.addSubview(lineBar)
            lineBar.snp.makeConstraints { make in
                make.top.equalTo(previousBar.snp.bottom).offset(
                    index == 0 ? MessageListSkeletonView.Layout.titleToLineSpacing : MessageListSkeletonView.Layout.lineSpacing
                )
                make.left.equalTo(MessageListSkeletonView.Layout.contentHorizontalPadding)
                make.width.equalToSuperview().multipliedBy(config.lineWidthRatios[index]).offset(-MessageListSkeletonView.Layout.contentHorizontalPadding)
                make.height.equalTo(MessageListSkeletonView.Layout.lineBarHeight)
            }
            previousBar = lineBar
        }

        dateBar.backgroundColor = placeholderColor
        dateBar.layer.cornerRadius = MessageListSkeletonView.Layout.dateBarCornerRadius
        dateBar.layer.cornerCurve = .continuous
        panel.addSubview(dateBar)

        dateBar.snp.makeConstraints { make in
            make.top.equalTo(previousBar.snp.bottom).offset(MessageListSkeletonView.Layout.dateTopSpacing)
            make.left.equalTo(MessageListSkeletonView.Layout.contentHorizontalPadding)
            make.width.equalTo(MessageListSkeletonView.Layout.dateBarWidth)
            make.height.equalTo(MessageListSkeletonView.Layout.dateBarHeight)
            make.bottom.equalTo(-MessageListSkeletonView.Layout.contentBottomPadding)
        }
    }

    private func makePlaceholderBar() -> UIView {
        let view = UIView()
        view.backgroundColor = placeholderColor
        view.layer.cornerRadius = MessageListSkeletonView.Layout.lineBarCornerRadius
        view.layer.cornerCurve = .continuous
        return view
    }
}
