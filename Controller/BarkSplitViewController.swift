//
//  BarkSplitViewController.swift
//  Bark
//
//  Created by sidguan on 2024/6/30.
//  Copyright © 2024 Fin. All rights reserved.
//

import Material
import UIKit

@available(iOS 14, *)
class BarkSplitViewController: UISplitViewController {
    let sectionViewController = SectionViewController_iPad(viewModel: SectionViewModel())
    // Compact 下替换显示成 BarkTabBarController
    let compactController = BarkTabBarController()

    func initViewControllers() {
        self.setViewController(sectionViewController, for: .primary)
        // 设置默认打开页面
        let index: Int = Settings[.selectedViewControllerIndex] ?? 0
        self.setViewController(sectionViewController.viewControllers[index], for: .secondary)
        self.setViewController(compactController, for: .compact)
    }
}
