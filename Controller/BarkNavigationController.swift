//
//  BarkNavigationController.swift
//  Bark
//
//  Created by huangfeng on 2018/6/25.
//  Copyright © 2018 Fin. All rights reserved.
//

import UIKit
import Material

class BarkNavigationController: NavigationController{
    override func prepare() {
        super.prepare()
        isMotionEnabled = true
        motionNavigationTransitionType = .autoReverse(presenting: .fade)
        
        guard let v = navigationBar as? NavigationBar else {
            return
        }
        
        v.depthPreset = .none
        v.dividerColor = Color.grey.lighten2
        
        navigationBar.backgroundColor = Color.blue.darken2
        
        statusBarStyle = .lightContent
        
    }
    
    override var childViewControllerForStatusBarStyle: UIViewController?{
        get {
            return self.topViewController
        }
    }
}

class BarkSnackbarController: SnackbarController {
    override var childViewControllerForStatusBarStyle: UIViewController?{
        return self.rootViewController
    }
}
