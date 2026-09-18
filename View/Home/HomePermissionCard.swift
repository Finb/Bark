//
//  HomePermissionCard.swift
//  Bark
//
//  Created by huangfeng on 8/25/26.
//  Copyright © 2026 Fin. All rights reserved.
//

import SnapKit
import UIKit

enum PermissionCardType {
    case notification
    case criticalAlert
    case granted

    var title: String {
        switch self {
        case .notification: return "notificationPermissionOff".localized
        case .criticalAlert: return "criticalAlertPermissionOff".localized
        case .granted: return "notificationPermissionOn".localized
        }
    }

    var detail: String {
        switch self {
        case .notification: return "notificationPermissionOffDetail".localized
        case .criticalAlert: return "criticalAlertPermissionOffDetail".localized
        case .granted: return "notificationPermissionOnDetail".localized
        }
    }

    var tintColor: UIColor {
        switch self {
        case .granted: return .systemGreen
        default: return .systemOrange
        }
    }

    var legacyIconBackgroundColor: UIColor {
        switch self {
        case .granted: return .systemGreen.withAlphaComponent(0.12)
        default: return BKColor.home.legacyAccentOrange
        }
    }

    var showsButton: Bool {
        switch self {
        case .granted: return false
        default: return true
        }
    }
}

final class HomePermissionCard: GlassView {
    let button: HomeGlassButton = {
        let button = HomeGlassButton()
        button.title = "goToSettings".localized
        if #available(iOS 27.0, *) {
            button.tintColor = .systemOrange
        }
        return button
    }()

    private let iconView: GlassView = {
        let iconView = GlassView()
        iconView.isUserInteractionEnabled = false
        return iconView
    }()
    private let iconImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "bell.badge.fill"))
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()
    private let detailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    private var buttonLeadingConstraint: Constraint?

    func configure(type: PermissionCardType) {
        titleLabel.text = type.title
        detailLabel.text = type.detail
        iconImageView.tintColor = type.tintColor
        iconView.glassTintColor = type.tintColor.withAlphaComponent(0.12)
        iconView.legacyBackgroundColor = type.legacyIconBackgroundColor
        button.isHidden = !type.showsButton
        buttonLeadingConstraint?.isActive = type.showsButton
    }

    override init() {
        super.init()
        let labels = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        labels.axis = .vertical
        labels.spacing = 2
        iconView.contentView.addSubview(iconImageView)
        contentView.addSubview(iconView)
        contentView.addSubview(labels)
        contentView.addSubview(button)
        iconImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }
        labels.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
            make.top.bottom.equalToSuperview().inset(16)
        }
        button.snp.makeConstraints { make in
            self.buttonLeadingConstraint = make.leading.greaterThanOrEqualTo(labels.snp.trailing).offset(6).constraint
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.height.equalTo(36)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
