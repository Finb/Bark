//
//  BarkNavigationController.swift
//  Bark
//
//  Created by huangfeng on 2018/6/25.
//  Copyright © 2018 Fin. All rights reserved.
//

import UIKit
import Material
import UINavigationItem_Margin
class BarkNavigationController: UINavigationController{
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.leftMargin = 8
        self.navigationItem.rightMargin = 8
    }
}

class BarkSnackbarController: SnackbarController {
    override var childForStatusBarStyle: UIViewController?{
        return self.rootViewController
    }
}
