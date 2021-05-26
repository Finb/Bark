//
//  BarkNavigationController.swift
//  Bark
//
//  Created by huangfeng on 2018/6/25.
//  Copyright © 2018 Fin. All rights reserved.
//

import UIKit
import Material
class BarkNavigationController: UINavigationController{
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationBar.prefersLargeTitles = true
    }
}

class BarkSnackbarController: SnackbarController {
    override var childForStatusBarStyle: UIViewController?{
        return self.rootViewController
    }
}

class StateStorageTabBarController: UITabBarController, UITabBarControllerDelegate {

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.delegate == nil {
            if let index:Int = Settings[.selectedViewControllerIndex] {
                self.selectedIndex = index
            }
            self.delegate = self
        }
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        Settings[.selectedViewControllerIndex] = self.selectedIndex
    }
}
