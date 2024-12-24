//
//  ShowLessAndClearView.swift
//  Bark
//
//  Created by huangfeng on 12/23/24.
//  Copyright © 2024 Fin. All rights reserved.
//

import SnapKit
import UIKit

class ShowLessAndClearView: UIView {
    private let showLessView = ShowLessView()
    private let clearView = ClearView()
    
    private var clearViewWidthConstraint: Constraint? = nil
    
    var showLessAction: (() -> Void)?
    var clearAction: (() -> Void)?
    
    init() {
        super.init(frame: .zero)
        self.addSubview(showLessView)
        self.addSubview(clearView)
        showLessView.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.right.equalTo(-28 - 5)
        }
        clearView.snp.makeConstraints { make in
            make.centerY.right.equalToSuperview()
            make.height.equalTo(28)
            self.clearViewWidthConstraint = make.width.equalTo(28).constraint
        }
        
        clearView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(clearTap)))
        showLessView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showLesstTap)))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func clearTap() {
        if clearView.isExpanded {
            self.clearAction?()
            return
        }
        self.buttonExpandAnimation(isClearViewExpanded: true)
    }
    
    @objc private func showLesstTap() {
        if showLessView.isExpanded {
            self.showLessAction?()
            return
        }
        self.buttonExpandAnimation(isClearViewExpanded: false)
    }
    
    private func buttonExpandAnimation(isClearViewExpanded: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.showLessView.isExpanded = !isClearViewExpanded
            self.clearView.isExpanded = isClearViewExpanded
            self.clearViewWidthConstraint?.update(offset: isClearViewExpanded ? self.bounds.width - 28 - 5 : 28)
            self.layoutIfNeeded()
        }
    }
}

private class ShowLessView: UIView {
    let panel: UIView = {
        let view = UIView()
        view.backgroundColor = BKColor.grey.lighten5
        view.layer.cornerRadius = 28 / 2
        view.clipsToBounds = true
        return view
    }()
        
    let downArrow: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "baseline_keyboard_arrow_down_black_24pt")?.withRenderingMode(.alwaysTemplate))
        imageView.tintColor = BKColor.grey.darken2
        return imageView
    }()

    let showLessLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(ofSize: 12)
        label.textColor = BKColor.grey.darken3
        label.text = NSLocalizedString("showLess")
        return label
    }()
    
    var isExpanded: Bool = true {
        didSet {
            refreshPanelLayout()
        }
    }

    init() {
        super.init(frame: .zero)
        self.addSubview(panel)
        panel.addSubview(downArrow)
        panel.addSubview(showLessLabel)
        
        downArrow.snp.makeConstraints { make in
            make.left.equalTo(self).offset(2)
            make.top.equalTo(self).offset(2)
            make.bottom.equalTo(self).offset(-2)
            make.width.height.equalTo(24)
        }
        
        showLessLabel.snp.makeConstraints { make in
            make.left.equalTo(downArrow.snp.right).offset(2)
            make.centerY.equalTo(self)
            make.right.equalTo(self).offset(-10)
        }
        
        refreshPanelLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func refreshPanelLayout() {
        // 收缩时，只收缩 panel ，控件实际宽度不变，主要用于动画
        panel.snp.remakeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            if isExpanded {
                make.right.equalToSuperview()
            } else {
                make.width.equalTo(self.snp.height)
            }
        }
    }
}

private class ClearView: UIView {
    let clearIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "baseline_close_white_48pt")?.withRenderingMode(.alwaysTemplate))
        imageView.tintColor = BKColor.grey.darken2
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    let clearLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(ofSize: 12)
        label.textColor = BKColor.grey.darken3
        label.text = NSLocalizedString("clear")
        label.alpha = 0
        return label
    }()
    
    var isExpanded: Bool = false {
        didSet {
            self.clearLabel.alpha = self.isExpanded ? 1 : 0
            self.clearIcon.alpha = self.isExpanded ? 0 : 1
        }
    }
    
    init() {
        super.init(frame: .zero)
        self.backgroundColor = BKColor.grey.lighten5
        self.layer.cornerRadius = 28 / 2
        self.clipsToBounds = true
        
        self.addSubview(clearLabel)
        self.addSubview(clearIcon)
        
        clearIcon.snp.remakeConstraints { make in
            make.right.equalToSuperview().offset(-4)
            make.top.equalToSuperview().offset(4)
            make.bottom.equalToSuperview().offset(-4)
            make.width.height.equalTo(20)
        }
        
        clearLabel.snp.remakeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
