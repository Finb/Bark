//
//  BarkTabBarController.swift
//  Bark
//
//  Created by huangfeng on 2024/8/20.
//  Copyright © 2024 Fin. All rights reserved.
//

import Material
import UIKit

class BarkTabBarController: StateStorageTabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBar.tintColor = BKColor.grey.darken4
        
        self.viewControllers = [
            BarkNavigationController(rootViewController: HomeViewController(viewModel: HomeViewModel())),
            BarkNavigationController(rootViewController: MessageListViewController(viewModel: MessageListViewModel())),
            BarkNavigationController(rootViewController: MessageSettingsViewController(viewModel: MessageSettingsViewModel()))
        ]
        
        let tabBarItems = [UITabBarItem(title: NSLocalizedString("service"), image: UIImage(named: "baseline_gite_black_24pt"), tag: 0),
                           UITabBarItem(title: NSLocalizedString("historyMessage"), image: Icon.history, tag: 1),
                           UITabBarItem(title: NSLocalizedString("settings"), image: UIImage(named: "baseline_manage_accounts_black_24pt"), tag: 2)]
        for (index, viewController) in self.viewControllers!.enumerated() {
            viewController.tabBarItem = tabBarItems[index]
        }
    }
}
