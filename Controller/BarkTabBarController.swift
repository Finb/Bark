//
//  BarkTabBarController.swift
//  Bark
//
//  Created by huangfeng on 2024/8/20.
//  Copyright © 2024 Fin. All rights reserved.
//

import Material
import UIKit

class BarkTabBarController: StateRestoringTabBarContr {
    /// Show a sidebar instead of the tab bar when the width allows it (iOS 27+).
    /// Off when embedded as the compact column of `BarkSplitViewController`, which owns its own sidebar.
    var prefersSidebar = false

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBar.tintColor = BKColor.grey.darken4
        
        let viewControllers: [UIViewController] = [
            BarkNavigationController(rootViewController: HomeViewController(viewModel: HomeViewModel())),
            BarkNavigationController(rootViewController: MessageListViewController(viewModel: MessageListViewModel())),
            BarkNavigationController(rootViewController: MessageSettingsViewController(viewModel: MessageSettingsViewModel()))
        ]
        let tabBarItems: [(title: String, image: UIImage?)] = [
            ("service".localized, UIImage(named: "baseline_gite_black_24pt")),
            ("historyMessage".localized, Icon.history),
            ("settings".localized, UIImage(named: "baseline_manage_accounts_black_24pt"))
        ]

        if #available(iOS 27.0, *), prefersSidebar {
            // One set of pages for every width: a foldable switching between its
            // compact and regular displays keeps navigation state, and the regular
            // display gets a sidebar instead of a stretched tab bar.
            self.mode = .tabSidebar
            self.sidebar.preferredPlacement = .sidebar
            self.tabs = zip(viewControllers, tabBarItems).enumerated().map { index, pair in
                let (viewController, item) = pair
                return UITab(title: item.title, image: item.image, identifier: "\(index)") { _ in viewController }
            }
        } else {
            self.viewControllers = viewControllers
            for (index, viewController) in viewControllers.enumerated() {
                viewController.tabBarItem = UITabBarItem(title: tabBarItems[index].title, image: tabBarItems[index].image, tag: index)
            }
        }
    }
}
