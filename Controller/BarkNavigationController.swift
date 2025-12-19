//
//  BarkNavigationController.swift
//  Bark
//
//  Created by huangfeng on 2018/6/25.
//  Copyright © 2018 Fin. All rights reserved.
//

import Material
import RxSwift
import UIKit

class BarkNavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationBar.prefersLargeTitles = true
    }
}

class BarkSnackbarController: SnackbarController {
    override var childForStatusBarStyle: UIViewController? {
        return self.rootViewController
    }
}

enum TabPage: Int {
    case unknown = -1
    case service = 0
    case messageHistory = 1
    case settings = 2
}

class StateRestoringTabBarContr: UITabBarController, UITabBarControllerDelegate {
    // 标记当前显示的页面，再次点击相同的页面时当做页面点击事件。
    var currentSelectedIndex: Int = -1 {
        didSet {
            guard currentSelectedIndex >= 0 else {
                return
            }
            guard currentSelectedIndex < self.viewControllers?.count ?? 0 else {
                return
            }
            guard currentSelectedIndex != oldValue else {
                return
            }
            
            if currentSelectedIndex != self.selectedIndex {
                self.selectedIndex = currentSelectedIndex
            }
            
            guard oldValue >= 0 else {
                // 如果是 -1 代表是初始化时的赋值，不需要重复保存
                return
            }
            
            Settings[.selectedViewControllerIndex] = currentSelectedIndex
        }
    }

    // 点击当前页面的 tabBarItem ， 可以用以点击刷新当前页面等操作
    lazy var tabBarItemDidClick: Observable<TabPage> = self.rx.didSelect
        .flatMapLatest { _ -> Single<TabPage> in
            let single = Single<TabPage>.create { single in
                if self.currentSelectedIndex == self.selectedIndex {
                    single(.success(TabPage(rawValue: self.selectedIndex) ?? .unknown))
                }
                return Disposables.create()
            }
            return single
        }.share()

    var isFirstAppear = true
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isFirstAppear {
            isFirstAppear = false

            // 开启APP时，默认选择上次打开的页面
            self.currentSelectedIndex = Settings[.selectedViewControllerIndex] ?? 0

            // 保存打开的页面Index
            self.rx.didSelect.subscribe(onNext: { _ in
                self.currentSelectedIndex = self.selectedIndex
            }).disposed(by: rx.disposeBag)
        }
    }
}
