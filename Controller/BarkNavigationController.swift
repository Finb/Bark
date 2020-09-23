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
    }
}

class BarkSnackbarController: SnackbarController {
    override var childForStatusBarStyle: UIViewController?{
        return self.rootViewController
    }
}
