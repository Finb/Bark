//
//  MessageListViewController.swift
//  Bark
//
//  Created by huangfeng on 2020/5/25.
//  Copyright © 2020 Fin. All rights reserved.
//

import Material
import MJRefresh
import RealmSwift
import RxCocoa
import RxDataSources
import RxSwift
import UIKit
import UniformTypeIdentifiers

class MessageListViewController: BaseViewController<MessageListViewModel> {
    lazy var deleteButton: UIBarButtonItem = {
        if #available(iOS 14.0, *) {
            var menuElements = [UIMenuElement]()
            for range in [MessageDeleteTimeRange.lastHour, .today, .todayAndYesterday, .lastMonth, .allTime] {
                let action = UIAction(title: range.string) { [weak self] _ in
                    self?.clearAlert(range)
                }
                menuElements.append(action)
            }
            
            var subMenuElements = [UIMenuElement]()
            for range in [MessageDeleteTimeRange.beforeOneHour, .beforeToday, .beforeYesterday, .beforeOneMonth] {
                let action = UIAction(title: range.string) { [weak self] _ in
                    self?.clearAlert(range)
                }
                subMenuElements.append(action)
            }
            menuElements.append(UIMenu(title: NSLocalizedString("more"), children: subMenuElements))

            let addNewMenu = UIMenu(
                title: NSLocalizedString("clearFrom"),
                children: menuElements
            )
            let item = UIBarButtonItem(image: UIImage(named: "baseline_delete_outline_black_24pt"), menu: addNewMenu)
            item.accessibilityLabel = NSLocalizedString("clear")
            return item
        } else {
            let btn = BKButton()
            btn.setImage(UIImage(named: "baseline_delete_outline_black_24pt"), for: .normal)
            btn.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            btn.accessibilityLabel = NSLocalizedString("clear")
            return UIBarButtonItem(customView: btn)
        }
        
    }()
    
    let groupButton: UIBarButtonItem = {
        let btn = BKButton()
        btn.setImage(UIImage(named: "group_expand")?.withRenderingMode(.alwaysTemplate), for: .normal)
        btn.setImage(UIImage(named: "group_collapse")?.withRenderingMode(.alwaysTemplate), for: .selected)
        btn.imageView?.tintColor = BKColor.black
        btn.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        btn.accessibilityLabel = "toggle"
        return UIBarButtonItem(customView: btn)
    }()
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.backgroundColor = BKColor.background.primary
        tableView.register(MessageTableViewCell.self, forCellReuseIdentifier: "\(MessageTableViewCell.self)")
        tableView.register(MessageGroupTableViewCell.self, forCellReuseIdentifier: "\(MessageGroupTableViewCell.self)")
        // 设置了这个后，第一次进页面 LargeTitle 就会收缩成小标题，不设置这个LargeTitle就是大标题显示
        // 谁特么能整的明白这个？
        // tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        
        // 替代 contentInset 设置一个 header
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 20))
        
        tableView.rx.setDelegate(self).disposed(by: rx.disposeBag)
        tableView.mj_footer = MJRefreshAutoFooter()
        
        return tableView
    }()
    
    /// 展开的群组
    private var expandedGroup: Set<String> = []
    /// 下拉刷新标记字段
    private var canRefresh = true
    
    /// 群组中删除消息的事件流
    private let itemDeleteInGroupRelay = PublishRelay<MessageItemModel>()
    /// 下拉刷新事件流
    private let refreshRelay = PublishRelay<Void>()
    /// 重新刷新已加载的页的数据 （最多10页）
    private let reloadRelay = PublishRelay<Void>()
    /// 按时间范围清除消息事件流
    private let clearRelay = PublishRelay<MessageDeleteTimeRange>()

    override func makeUI() {
        navigationItem.searchController = UISearchController(searchResultsController: nil)
        navigationItem.searchController?.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController?.delegate = self
        
        navigationItem.setBarButtonItems(items: [deleteButton, groupButton], position: .right)
        
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        if #available(iOS 14.0, *) {
            // iOS 14 以上，使用 UIMenu
        } else {
            // 使用 UIAlertController
            subscribeDeleteTap()
        }
        
        // 点击tab按钮，回到顶部
        Client.shared.currentTabBarController?
            .tabBarItemDidClick
            .filter { $0 == .messageHistory }
            .subscribe(onNext: { [weak self] _ in
                self?.scrollToTop()
            }).disposed(by: self.rx.disposeBag)
        
        NotificationCenter.default.rx
            .notification(UIApplication.willEnterForegroundNotification)
            .delay(.milliseconds(500), scheduler: MainScheduler.instance) // 延迟0.5秒，等待数据库 Results 更新到最新数据集
            .subscribe(onNext: { [weak self] _ in
                self?.reloadRelay.accept(())
            }).disposed(by: rx.disposeBag)
        
        // 点击群组消息，展开群
        tableView.rx.itemSelected.subscribe(onNext: { [weak self] indexPath in
            guard let self else { return }
            if let cell = self.tableView.cellForRow(at: indexPath) as? MessageGroupTableViewCell {
                if !cell.isExpanded {
                    UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2) {
                        self.tableView.performBatchUpdates {
                            cell.isExpanded = true
                        }
                    }
                    if let groupName = cell.cellData?.groupName {
                        self.expandedGroup.insert(groupName)
                    }
                }
            }
        }).disposed(by: rx.disposeBag)
    }

    // tableView 数据源
    private lazy var dataSource = RxTableViewSectionedAnimatedDataSource<MessageSection>(
        animationConfiguration: AnimationConfiguration(
            insertAnimation: .none,
            reloadAnimation: .none,
            deleteAnimation: .left
        ),
        configureCell: { [weak self] _, tableView, _, item -> UITableViewCell in
            guard let self else { return UITableViewCell() }
            
            switch item {
            case .message(let message):
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(MessageTableViewCell.self)") as? MessageTableViewCell else {
                    return UITableViewCell()
                }
                cell.tapAction = { [weak self, weak cell] message, sourceView in
                    guard let self, let cell else { return }
                    self.alertMessage(message: message, sourceView: sourceView, sourceCell: cell)
                }
                cell.message = message
                return cell
            case .messageGroup(let title, let totalCount, let messages):
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(MessageGroupTableViewCell.self)") as? MessageGroupTableViewCell else {
                    return UITableViewCell()
                }
                cell.showLessAction = { [weak self, weak cell] in
                    guard let self else { return }
                    UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2) {
                        self.tableView.performBatchUpdates {
                            cell?.isExpanded = false
                        }
                        if let groupName = cell?.cellData?.groupName {
                            self.expandedGroup.remove(groupName)
                        }
                    }
                }
                cell.showGroupMessageAction = { [weak self] group in
                    let viewModel = MessageListViewModel(sourceType: .group(group))
                    let controller = MessageListViewController(viewModel: viewModel)
                    self?.navigationController?.pushViewController(controller, animated: true)
                }
                cell.clearAction = { [weak self, weak cell] in
                    guard let self, let cell, let indexPath = self.tableView.indexPath(for: cell) else { return }
                    self.tableView.dataSource?.tableView?(self.tableView, commit: .delete, forRowAt: indexPath)
                }
                cell.tapAction = { [weak self, weak cell] message, sourceView in
                    guard let self, let cell else { return }
                    self.alertMessage(message: message, sourceView: sourceView, sourceCell: cell)
                }
                cell.cellData = (title, totalCount, messages)
                cell.isExpanded = self.expandedGroup.contains(title)
                return cell
            }

        }, canEditRowAtIndexPath: { _, _ in
            true
        }
    )
    
    override func bindViewModel() {
        guard let groupBtn = groupButton.customView as? BKButton else {
            return
        }
        
        let output = viewModel.transform(
            input: MessageListViewModel.Input(
                refresh: refreshRelay.asDriver(onErrorDriveWith: .empty()),
                loadMore: tableView.mj_footer!.rx.refresh.asDriver(),
                itemDelete: tableView.rx.modelDeleted(MessageListCellItem.self).asDriver(),
                itemDeleteInGroup: itemDeleteInGroupRelay.asDriver(onErrorDriveWith: .empty()),
                delete: clearRelay.asDriver(onErrorDriveWith: .empty()),
                groupToggleTap: groupBtn.rx.tap.asDriver(),
                searchText: navigationItem.searchController!.searchBar.rx.text.asObservable(),
                reload: reloadRelay.asDriver(onErrorDriveWith: .empty())
            ))
        
        // tableView 刷新状态
        output.refreshAction
            .drive(tableView.rx.refreshAction)
            .disposed(by: rx.disposeBag)
        
        output.messages
            .drive(tableView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)
        
        // 选择群组
        output.type
            .drive(onNext: { [weak self] type in
                (self?.groupButton.customView as? UIButton)?.isSelected = type == .group
            }).disposed(by: rx.disposeBag)
        
        // 标题
        output.title
            .drive(self.navigationItem.rx.title).disposed(by: rx.disposeBag)
        
        // 数据库初始化出错错误提示
        output.errorAlert
            .drive(onNext: { [weak self] error in
                let alertController = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Copy2"), style: .default, handler: { _ in
                    UIPasteboard.general.string = error
                }))
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: .cancel, handler: nil))
                self?.present(alertController, animated: true, completion: nil)
            }).disposed(by: rx.disposeBag)
        
        output.groupToggleButtonHidden
            .drive((groupButton.customView as! UIButton).rx.isHidden).disposed(by: rx.disposeBag)
    }
    
    private func subscribeDeleteTap() {
        guard let deleteBtn = deleteButton.customView as? BKButton else {
            return
        }
        deleteBtn.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let self else { return }
            
            let alertController = UIAlertController(title: nil, message: NSLocalizedString("clearFrom"), preferredStyle: .actionSheet)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("lastHour"), style: .default, handler: { [weak self] _ in
                self?.clearAlert(.lastHour)
            }))
            alertController.addAction(UIAlertAction(title: NSLocalizedString("today"), style: .default, handler: { [weak self] _ in
                self?.clearAlert(.today)
            }))
            alertController.addAction(UIAlertAction(title: NSLocalizedString("todayAndYesterday"), style: .default, handler: { [weak self] _ in
                self?.clearAlert(.todayAndYesterday)
            }))
            alertController.addAction(UIAlertAction(title: NSLocalizedString("allTime"), style: .default, handler: { [weak self] _ in
                self?.clearAlert(.allTime)
            }))
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: .cancel, handler: nil))
            if UIDevice.current.userInterfaceIdiom == .pad {
                alertController.modalPresentationStyle = .popover
                if #available(iOS 16.0, *) {
                    alertController.popoverPresentationController?.sourceItem = self.deleteButton
                } else {
                    alertController.popoverPresentationController?.barButtonItem = self.deleteButton
                }
            }
            self.navigationController?.present(alertController, animated: true, completion: nil)
        }).disposed(by: rx.disposeBag)
    }
    
    func clearAlert(_ range: MessageDeleteTimeRange) {
        let alertController = UIAlertController(title: nil, message: "\(NSLocalizedString("clearFrom"))\n\(range.string)", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("clear"), style: .destructive, handler: { [weak self] _ in
            self?.clearRelay.accept(range)
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: .cancel, handler: nil))
        self.navigationController?.present(alertController, animated: true, completion: nil)
    }
    
    private func alertMessage(message: MessageItemModel, sourceView: MessageItemView, sourceCell: UITableViewCell) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // 复制
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Copy2"), style: .default, handler: { [weak self]
            (_: UIAlertAction) in
                if #available(iOS 14.0, *) {
                    var items = [[String: Any]]()
                    items.append([UTType.utf8PlainText.identifier: message.attributedText?.string ?? ""])
                    if let image = sourceView.imageView.image {
                        items.append([UTType.image.identifier: image])
                    }
                    UIPasteboard.general.items = items
                } else {
                    UIPasteboard.general.string = message.attributedText?.string ?? ""
                }
                self?.showSnackbar(text: NSLocalizedString("Copy"))
        }))
        // 删除
        alertController.addAction(UIAlertAction(title: NSLocalizedString("removeMessage"), style: .destructive, handler: { [weak self]
            (_: UIAlertAction) in
                guard let self, let indexPath = self.tableView.indexPath(for: sourceCell) else { return }
                if sourceCell is MessageTableViewCell {
                    // 单个消息，把cell删除
                    self.tableView.dataSource?.tableView?(self.tableView, commit: .delete, forRowAt: indexPath)
                } else if sourceCell is MessageGroupTableViewCell {
                    // 群组消息，只能删除群组中需删除的消息
                    self.itemDeleteInGroupRelay.accept(message)
                }
        }))
        // 取消
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: .cancel, handler: { _ in }))
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            alertController.popoverPresentationController?.sourceView = sourceView.superview
            alertController.popoverPresentationController?.sourceRect = sourceView.frame
            alertController.modalPresentationStyle = .popover
        }
        
        self.navigationController?.present(alertController, animated: true, completion: nil)
    }
    
    private func scrollToTop() {
        if self.tableView.visibleCells.count > 0 {
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
    }
}

extension MessageListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .destructive, title: NSLocalizedString("removeMessage")) { [weak self] _, _, actionPerformed in
            guard let self else { return }
            
            if self.tableView.cellForRow(at: indexPath) is MessageTableViewCell {
                // 单个消息直接删除，不弹出提示
                self.tableView.dataSource?.tableView?(self.tableView, commit: .delete, forRowAt: indexPath)
                actionPerformed(true)
                return
            }
            
            // 群组消息删除，弹出个确认提示
            let alertView = UIAlertController(title: nil, message: NSLocalizedString("removeNotice"), preferredStyle: .alert)
            alertView.addAction(UIAlertAction(title: NSLocalizedString("removeMessage"), style: .destructive, handler: { _ in
                self.tableView.dataSource?.tableView?(self.tableView, commit: .delete, forRowAt: indexPath)
                actionPerformed(true)
            }))
            alertView.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: .cancel, handler: { _ in
                actionPerformed(false)
            }))
            self.present(alertView, animated: true, completion: nil)
        }

        let configuration = UISwipeActionsConfiguration(actions: [action])
        return configuration
    }
}

extension MessageListViewController: UISearchControllerDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if self.navigationItem.searchController?.searchBar.isFirstResponder == true {
            self.navigationItem.searchController?.searchBar.resignFirstResponder()
        }
    }

    func willDismissSearchController(_ searchController: UISearchController) {
        if !searchController.searchBar.isFirstResponder {
            /*
             searchBar 不在焦点时，点击搜索框右边的取消按钮时，不会触发 searchBar.rx.text 更改事件
             searchBar.rx.text 将一直保留为最后的文本
             但我们预期是要更新为 nil 的，因为再次点击searchBar，searchBar.text 显示的是 nil
             可能对用户造成困惑，搜索框里没有输入任何keyword，但消息列表却被错误的keyword过滤了
             
             另外直接给 text 赋值，并不能触发 searchBar.rx.text，
             需要手动发送一下actions
             */
            searchController.searchBar.searchTextField.text = nil
            searchController.searchBar.searchTextField.sendActions(for: .editingDidEnd)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        if offset <= -10 && canRefresh {
            // 触发下拉刷新，并震动
            canRefresh = false
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            refreshRelay.accept(())
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        if offset >= 0 && !canRefresh {
            canRefresh = true
        }
    }
}
