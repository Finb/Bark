//
//  HomeSettingsCard.swift
//  Bark
//
//  Created by huangfeng on 8/25/26.
//  Copyright © 2026 Fin. All rights reserved.
//

import UIKit

final class HomeSettingsCard: GlassView {
    let serverRow = HomeSettingRow(title: "serverList".localized, symbolName: "server.rack", tintColor: .systemBlue, legacyBackgroundColor: BKColor.home.legacyAccentBlue)
    let cryptoRow = HomeSettingRow(title: "encryptionSettings".localized, symbolName: "key.fill", tintColor: .systemTeal, legacyBackgroundColor: BKColor.home.legacyAccentTeal)
    let soundsRow = HomeSettingRow(title: "customSounds".localized, symbolName: "speaker.wave.2.fill", tintColor: .systemOrange, legacyBackgroundColor: BKColor.home.legacyAccentOrange)

    override init() {
        super.init()
        let stack = UIStackView(arrangedSubviews: [serverRow, divider(), cryptoRow, divider(), soundsRow])
        stack.axis = .vertical
        stack.spacing = 4
        contentView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func divider() -> UIView {
        let container = UIView()
        let line = UIView()
        line.backgroundColor = BKColor.home.divider
        container.addSubview(line)
        line.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(44)
            make.top.trailing.bottom.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }
        return container
    }
}
