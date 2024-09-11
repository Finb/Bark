//
//  BarkSplitViewController.swift
//  Bark
//
//  Created by sidguan on 2024/6/30.
//  Copyright © 2024 Fin. All rights reserved.
//

import Material
import UIKit

@available(iOS 14, *)
class BarkSplitViewController: UISplitViewController {
    let sectionViewController = SectionViewController_iPad(viewModel: SectionViewModel())
    // Compact 下替换显示成 BarkTabBarController
    let compactController = BarkTabBarController()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.preferredDisplayMode = .oneBesideSecondary
        self.preferredSplitBehavior = .tile
        self.delegate = self
        initViewControllers()
    }

    func initViewControllers() {
        self.setViewController(sectionViewController, for: .primary)
        // 设置默认打开页面
        let index: Int = Settings[.selectedViewControllerIndex] ?? 0
        self.setViewController(sectionViewController.viewControllers[index], for: .secondary)
        DispatchQueue.main.async {
            self.sectionViewController.tableView.selectRow(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: .none)
        }
        self.setViewController(compactController, for: .compact)
    }
}

@available(iOS 14, *)
extension BarkSplitViewController: UISplitViewControllerDelegate {
    // 同步 sectionViewController 和 compactController 当前显示页面
    func splitViewControllerDidCollapse(_ svc: UISplitViewController) {
        guard let index: Int = Settings[.selectedViewControllerIndex] else {
            return
        }
        self.compactController.selectedIndex = index
    }

    func splitViewControllerDidExpand(_ svc: UISplitViewController) {
        guard let index: Int = Settings[.selectedViewControllerIndex] else {
            return
        }
        self.sectionViewController.tableView.selectRow(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: .none)
        self.setViewController(self.sectionViewController.viewControllers[index], for: .secondary)
    }
}
