//
//  BarkSplitViewController.swift
//  Bark
//
//  Created by sidguan on 2024/6/30.
//  Copyright © 2024 Fin. All rights reserved.
//

import UIKit
import Material

class BarkSplitViewController: UISplitViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
//        self.displayModeButtonItem.tintColor = BKColor.grey.darken4
//        self.delegate = self
        // Do any additional setup after loading the view.
    }
    
    func initViewControllers() {
        if #available(iOS 14, *) {
            let sectionViewController = BarkNavigationController(rootViewController: SectionViewController_iPad(viewModel: SectionViewModel()));
            let homeViewController = BarkNavigationController(rootViewController: HomeViewController(viewModel: HomeViewModel()));
            let tabBarController = StateStorageTabBarController()
            tabBarController.tabBar.tintColor = BKColor.grey.darken4
            
            let snackBarController = BarkSnackbarController(
                rootViewController: tabBarController
            )
            
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
            
            
            self.setViewController(sectionViewController, for: .primary)
            self.setViewController(homeViewController, for: .secondary)
            self.setViewController(snackBarController, for: .compact)
        }
    }
    
//    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
//        return true
//    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
