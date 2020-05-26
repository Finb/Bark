//
//  BaseViewController.swift
//  Bark
//
//  Created by huangfeng on 2018/6/25.
//  Copyright © 2018 Fin. All rights reserved.
//

import UIKit
import Material
class BaseViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = Color.grey.lighten5
        self.navigationItem.leftMargin = 8
        self.navigationItem.rightMargin = 8
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        get {
            return .lightContent
        }
    }
}
