//
//  BaseViewController.swift
//  Bark
//
//  Created by huangfeng on 2018/6/25.
//  Copyright © 2018 Fin. All rights reserved.
//

import Material
import UIKit

class BaseViewController<T>: UIViewController where T: ViewModel {
    let viewModel: T
    init(viewModel: T) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = BKColor.background.primary
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            navigationItem.largeTitleDisplayMode = .never
        } else {
            navigationItem.largeTitleDisplayMode = .automatic
        }
        makeUI()
    }

    var isViewModelBinded = false
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !isViewModelBinded {
            isViewModelBinded = true
            self.bindViewModel()
        }
    }
    
    func makeUI() {}

    func bindViewModel() {}
}
