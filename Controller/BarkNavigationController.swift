//
//  BarkNavigationController.swift
//  Bark
//
//  Created by huangfeng on 2018/6/25.
//  Copyright © 2018 Fin. All rights reserved.
//

import UIKit
import Material
import RxSwift

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

enum TabPage: Int {
    case unknown = -1
    case service = 0
    case messageHistory = 1
    case settings = 2
}

class StateStorageTabBarController: UITabBarController, UITabBarControllerDelegate {
    
    // 标记当前显示的页面，再次点击相同的页面时当做页面点击事件。
    var currentSelectedIndex: Int = 0
    
    // 点击当前页面的 tabBarItem ， 可以用以点击刷新当前页面等操作
    lazy var tabBarItemDidClick: Observable<TabPage> = {
        return self.rx.didSelect
            .flatMapLatest { _ -> Single<TabPage> in
                let single = Single<TabPage>.create { single in
                    if self.currentSelectedIndex == self.selectedIndex {
                        single(.success(TabPage(rawValue: self.selectedIndex) ?? .unknown))
                    }
                    self.currentSelectedIndex = self.selectedIndex
                    return Disposables.create()
                }
                return single
            }.share()
    }()

    var isFirstAppear = true
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isFirstAppear {
            isFirstAppear = false
            
            //开启APP时，默认选择上次打开的页面
            if let index:Int = Settings[.selectedViewControllerIndex] {
                self.selectedIndex = index
                self.currentSelectedIndex = index
            }
            //保存打开的页面Index
            self.rx.didSelect.subscribe(onNext: {_ in
                Settings[.selectedViewControllerIndex] = self.selectedIndex
            }).disposed(by: rx.disposeBag)
        }

    }
}
