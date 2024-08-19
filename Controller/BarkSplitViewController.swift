//
//  BarkSplitViewController.swift
//  Bark
//
//  Created by sidguan on 2024/6/30.
//  Copyright © 2024 Fin. All rights reserved.
//

import Material
import UIKit

class BarkSplitViewController: UISplitViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // 暂时没找到 oneOverSecondary 模式下，怎么显示左侧导航栏按钮
        // 先强制显示 primary 吧
        self.preferredDisplayMode = .oneBesideSecondary
        self.delegate = self
    }

    let sectionViewController = BarkNavigationController(
        rootViewController: SectionViewController_iPad(viewModel: SectionViewModel())
    )
    let homeViewController = BarkNavigationController(
        rootViewController: HomeViewController(viewModel: HomeViewModel())
    )
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
        self.viewControllers = [sectionViewController, homeViewController]
    }
}

extension BarkSplitViewController: UISplitViewControllerDelegate {
    func primaryViewController(forExpanding splitViewController: UISplitViewController) -> UIViewController? {
        sectionViewController
    }

    func primaryViewController(forCollapsing splitViewController: UISplitViewController) -> UIViewController? {
        snackBarController
    }
}
