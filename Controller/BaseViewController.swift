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
        self.navigationItem.backButton.tintColor = UIColor.white
        self.view.backgroundColor = Color.grey.lighten5
        navigationItem.titleLabel.textColor = .white
        navigationItem.titleLabel.font = UIFont.systemFont(ofSize: 16)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        get {
            return .lightContent
        }
    }
}
