//
//  CustomTapTextView.swift
//  Bark
//
//  Created by huangfeng on 12/30/24.
//  Copyright © 2024 Fin. All rights reserved.
//

import UIKit

/// 可以自定义点击事件的 UITextView，同时保留 UITextView 的所有其他手势
/// 此 TextView  不可编辑， 不可滚动
class CustomTapTextView: UITextView, UIGestureRecognizerDelegate {
    /// 点击手势，如果有选中文字，则不触发
    private lazy var tapGesture = UITapGestureRecognizer(target: self, action: #selector(tap))
    /// 双击手势，只是为了让 tapGesture 不要在双击选中文本时触发，没有其他作用
    private let doubleTapGesture = UITapGestureRecognizer()
    /// UITextView 自带的点击链接手势
    private var linkTapGesture: UIGestureRecognizer? = nil
    
    /// 额外的单击事件
    var customTapAction: (() -> Void)?
    
    init() {
        super.init(frame: .zero, textContainer: nil)
        
        self.backgroundColor = UIColor.clear
        self.isEditable = false
        self.dataDetectorTypes = [.phoneNumber, .link]
        self.isScrollEnabled = false
        self.textContainerInset = .zero
        self.textContainer.lineFragmentPadding = 0
        
        tapGesture.delegate = self
        self.addGestureRecognizer(tapGesture)
        
        self.linkTapGesture = self.gestureRecognizers?.first { $0 is UITapGestureRecognizer && $0.name == "UITextInteractionNameLinkTap" }
        
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.delegate = self
        self.addGestureRecognizer(doubleTapGesture)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func tap() {
        self.customTapAction?()
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == doubleTapGesture {
            return true
        }
        return false
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == tapGesture {
            if self.selectedRange.length > 0 {
                return false
            }
        }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == tapGesture {
            if otherGestureRecognizer == doubleTapGesture {
                return true
            }
            if otherGestureRecognizer == linkTapGesture {
                return true
            }
        }
        return false
    }
}
