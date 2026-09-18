//
//  GlassView.swift
//  Bark
//
//  Created by huangfeng on 8/25/26.
//  Copyright © 2026 Fin. All rights reserved.
//

import SnapKit
import UIKit

class GlassView: UIView {
    private let effectView: UIVisualEffectView?
    private let surfaceView: UIView

    var cornerRadius: CGFloat = 22 {
        didSet {
            layer.cornerRadius = cornerRadius
            surfaceView.layer.cornerRadius = cornerRadius
        }
    }
    var glassTintColor: UIColor? {
        didSet {
            updateEffect()
        }
    }
    var isInteractive: Bool = false {
        didSet {
            updateEffect()
        }
    }
    var legacyBackgroundColor: UIColor? {
        didSet {
            if #unavailable(iOS 27.0) {
                surfaceView.backgroundColor = legacyBackgroundColor ?? BKColor.background.secondary
            }
        }
    }

    var contentView: UIView {
        effectView?.contentView ?? surfaceView
    }

    init() {
        if #available(iOS 27.0, *) {
            let effectView = UIVisualEffectView()
            effectView.clipsToBounds = false
            self.effectView = effectView
            surfaceView = effectView
        } else {
            effectView = nil
            surfaceView = UIView()
        }
        super.init(frame: .zero)

        layer.cornerRadius = 22
        surfaceView.layer.cornerRadius = 22
        addSubview(surfaceView)
        surfaceView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        if #available(iOS 27.0, *) {
            updateEffect()
        } else {
            surfaceView.clipsToBounds = true
            surfaceView.backgroundColor = BKColor.background.secondary
            surfaceView.layer.borderWidth = 1 / UIScreen.main.scale
            surfaceView.layer.borderColor = BKColor.home.legacyBorder.cgColor

            layer.shadowOpacity = 0
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateEffect() {
        guard #available(iOS 27.0, *) else {
            return
        }
        let effect = UIGlassEffect(style: .regular)
        effect.tintColor = glassTintColor
        effect.isInteractive = isInteractive
        effectView?.effect = effect
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #unavailable(iOS 27.0) {
            surfaceView.layer.borderColor = BKColor.home.legacyBorder.cgColor
        }
    }
}
