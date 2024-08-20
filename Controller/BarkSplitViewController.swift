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
    // Compact 下替换显示成 snackBarController
    let snackBarController: StateStorageTabBarController = {
        let tabBarController = StateStorageTabBarController()
        tabBarController.tabBar.tintColor = BKColor.grey.darken4
        
        tabBarController.viewControllers = [
            BarkNavigationController(rootViewController: HomeViewController(viewModel: HomeViewModel())),
            BarkNavigationController(rootViewController: MessageListViewController(viewModel: MessageListViewModel())),
            BarkNavigationController(rootViewController: MessageSettingsViewController(viewModel: MessageSettingsViewModel()))
        ]
        
        let tabBarItems = [
            UITabBarItem(title: NSLocalizedString("service"), image: UIImage(named: "baseline_gite_black_24pt"), tag: 0),
            UITabBarItem(title: NSLocalizedString("historyMessage"), image: Icon.history, tag: 1),
            UITabBarItem(title: NSLocalizedString("settings"), image: UIImage(named: "baseline_manage_accounts_black_24pt"), tag: 2)
        ]
        for (index, viewController) in tabBarController.viewControllers!.enumerated() {
            viewController.tabBarItem = tabBarItems[index]
        }
        return tabBarController
    }()

    func initViewControllers() {
        self.setViewController(sectionViewController, for: .primary)
        // 设置默认打开页面
        let index: Int = Settings[.selectedViewControllerIndex] ?? 0
        self.setViewController(sectionViewController.viewControllers[index], for: .secondary)
        self.setViewController(snackBarController, for: .compact)
    }
}
