//
//  UINavigationItem+Extension.swift
//  Bark
//
//  Created by huangfeng on 2020/9/23.
//  Copyright © 2020 Fin. All rights reserved.
//

import UIKit

// 如果第一个 item 是系统自带的 UIBarButtonItem ，则距离导航栏左右距离只有8
// 自己定义的的则最少有16，太宽了
// 所以先用 一个 fixedSpace UIBarButtonItem 先把距离给缩短点，
// 然后用个 AlignmentRectInsetsOverridable 把自己的按钮往 左/右 挪动，减少距离
// 用 HitTestSlopable 增加点击区域
enum UINavigationItemPosition {
    case left
    case right
}

extension UINavigationItem {
    func setLeftBarButtonItem(item: UIBarButtonItem) {
        setBarButtonItems(items: [item], position: .left)
    }

    func setRightBarButtonItem(item: UIBarButtonItem) {
        setBarButtonItems(items: [item], position: .right)
    }

    func setBarButtonItems(items: [UIBarButtonItem], position: UINavigationItemPosition) {
        if #available(iOS 26.0, *) {
            // iOS 26 之后的版本，不再微调间距
            if position == .left {
                self.leftBarButtonItems = items
            } else {
                self.rightBarButtonItems = items
            }
            return
        }
        
        guard items.count > 0 else {
            self.leftBarButtonItems = nil
            return
        }
        var buttonItems = items
        if #available(iOS 11.0, *) {
            for item in buttonItems {
                guard let view = item.customView else { continue }
                item.customView?.translatesAutoresizingMaskIntoConstraints = false
                (item.customView as? HitTestSlopable)?.hitTestSlop = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
                (item.customView as? AlignmentRectInsetsOverridable)?.alignmentRectInsetsOverride = UIEdgeInsets(top: 0, left: position == .left ? 8 : -8, bottom: 0, right: position == .left ? -8 : 8)
                item.customView?.snp.makeConstraints { make in
                    make.width.equalTo(view.bounds.size.width > 24 ? view.bounds.width : 24)
                    make.height.equalTo(view.bounds.size.height > 24 ? view.bounds.height : 24)
                }
            }
            buttonItems.insert(UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil), at: 0)
        } else {
            let spacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
            spacer.width = -8
            buttonItems.insert(spacer, at: 0)
        }
        if position == .left {
            self.leftBarButtonItems = buttonItems
        } else {
            self.rightBarButtonItems = buttonItems
        }
    }
}
