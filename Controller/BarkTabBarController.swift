//
//  BarkTabBarController.swift
//  Bark
//
//  Created by huangfeng on 2024/8/20.
//  Copyright © 2024 Fin. All rights reserved.
//

import Material
import RealmSwift
import UIKit

class BarkTabBarController: StateRestoringTabBarContr {
    /// Show a sidebar instead of the tab bar when the width allows it (iOS 27+).
    /// Off when embedded as the compact column of `BarkSplitViewController`, which owns its own sidebar.
    private let prefersSidebar: Bool

    private var messageGroupsToken: NotificationToken?

    // UITabBarController loads its view inside init, so configuration read by
    // viewDidLoad must be set before calling super.
    init(prefersSidebar: Bool = false) {
        self.prefersSidebar = prefersSidebar
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        messageGroupsToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBar.tintColor = BKColor.grey.darken4

        let homeTitle = "service".localized
        let homeImage = UIImage(named: "baseline_gite_black_24pt")
        let historyTitle = "historyMessage".localized
        let historyImage = Icon.history
        let settingsTitle = "settings".localized
        let settingsImage = UIImage(named: "baseline_manage_accounts_black_24pt")

        let homeController = BarkNavigationController(rootViewController: HomeViewController(viewModel: HomeViewModel()))
        let messageListController = MessageListViewController(viewModel: MessageListViewModel())
        let settingsController = BarkNavigationController(rootViewController: MessageSettingsViewController(viewModel: MessageSettingsViewModel()))

        if #available(iOS 27.0, *), prefersSidebar {
            // One set of pages for every width: a foldable switching between its
            // compact and regular displays keeps navigation state, and the regular
            // display gets a sidebar instead of a stretched tab bar.
            self.mode = .tabSidebar
            self.sidebar.preferredPlacement = .sidebar
            self.delegate = self

            // The sidebar lists message groups under History, so a wide display
            // shows groups on the left and the selected group's messages on the right.
            let historyGroup = UITabGroup(
                title: historyTitle,
                image: historyImage,
                identifier: "\(TabPage.messageHistory.rawValue)",
                children: []
            ) { _ in messageListController }
            historyGroup.isSidebarDestination = true
            historyGroup.managingNavigationController = BarkNavigationController()

            self.tabs = [
                UITab(title: homeTitle, image: homeImage, identifier: "\(TabPage.service.rawValue)") { _ in homeController },
                historyGroup,
                UITab(title: settingsTitle, image: settingsImage, identifier: "\(TabPage.settings.rawValue)") { _ in settingsController }
            ]
            observeMessageGroups(historyGroup)
        } else {
            let historyController = BarkNavigationController(rootViewController: messageListController)
            homeController.tabBarItem = UITabBarItem(title: homeTitle, image: homeImage, tag: 0)
            historyController.tabBarItem = UITabBarItem(title: historyTitle, image: historyImage, tag: 1)
            settingsController.tabBarItem = UITabBarItem(title: settingsTitle, image: settingsImage, tag: 2)
            self.viewControllers = [homeController, historyController, settingsController]
        }
    }

    /// Keeps one sidebar child per message group, most recently active first.
    @available(iOS 27.0, *)
    private func observeMessageGroups(_ historyGroup: UITabGroup) {
        let groups = try! Realm()
            .objects(Message.self)
            .sorted(byKeyPath: "createDate", ascending: false)
            .distinct(by: ["group"])

        messageGroupsToken = groups.observe { [weak historyGroup] _ in
            guard let historyGroup else { return }
            let existing = Dictionary(uniqueKeysWithValues: historyGroup.children.map { ($0.identifier, $0) })
            let children: [UITab] = groups.map { message in
                let group = message.group
                let identifier = "group.\(group ?? "")"
                if let tab = existing[identifier] {
                    return tab
                }
                let tab = UITab(title: group ?? "default".localized, image: UIImage(systemName: "number"), identifier: identifier) { _ in
                    MessageListViewController(viewModel: MessageListViewModel(sourceType: .group(group)))
                }
                tab.preferredPlacement = .sidebarOnly
                return tab
            }
            if let selected = historyGroup.selectedChild, !children.contains(where: { $0 === selected }) {
                historyGroup.selectedChild = nil
            }
            historyGroup.children = children
        }
    }
}

@available(iOS 27.0, *)
extension BarkTabBarController {
    /// With the sidebar showing, a group's messages replace the full history list
    /// instead of being pushed on top of it; in a tab bar they stay pushed so
    /// the back button returns to all messages.
    func tabBarController(
        _ tabBarController: UITabBarController,
        displayedViewControllersFor tab: UITab,
        proposedViewControllers: [UIViewController]
    ) -> [UIViewController] {
        if let group = tab as? UITabGroup, group.selectedChild != nil, sidebar.isAvailable, !sidebar.isHidden {
            return []
        }
        return proposedViewControllers
    }
}
