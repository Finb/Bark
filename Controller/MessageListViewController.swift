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

enum MessageDeleteType: Int {
    case lastHour = 0
    case today
    case todayAndYesterday
    case allTime
    
    var string: String {
        return [
            NSLocalizedString("lastHour"),
            NSLocalizedString("today"),
            NSLocalizedString("todayAndYesterday"),
            NSLocalizedString("allTime")
        ][self.rawValue]
    }
}

class MessageListViewController: BaseViewController<MessageListViewModel> {
    let deleteButton: UIBarButtonItem = {
        let btn = BKButton()
        btn.setImage(UIImage(named: "baseline_delete_outline_black_24pt"), for: .normal)
        btn.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        return UIBarButtonItem(customView: btn)
    }()
    
    let groupButton: UIBarButtonItem = {
        let btn = BKButton()
        btn.setImage(UIImage(named: "group_expand")?.withRenderingMode(.alwaysTemplate), for: .normal)
        btn.setImage(UIImage(named: "group_collapse")?.withRenderingMode(.alwaysTemplate), for: .selected)
        btn.imageView?.tintColor = UIColor.black
        btn.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        return UIBarButtonItem(customView: btn)
    }()
    
    private var expandedGroup: Set<String> = []
    
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
        tableView.refreshControl = UIRefreshControl()
        
        return tableView
    }()
        
    override func makeUI() {
        navigationItem.searchController = UISearchController(searchResultsController: nil)
        navigationItem.searchController?.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController?.delegate = self
        
        navigationItem.setBarButtonItems(items: [deleteButton, groupButton], position: .right)
        
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 点击tab按钮，回到顶部
        Client.shared.currentTabBarController?
            .tabBarItemDidClick
            .filter { $0 == .messageHistory }
            .subscribe(onNext: { [weak self] _ in
                self?.scrollToTop()
            }).disposed(by: self.rx.disposeBag)
        
        // 打开APP时，历史消息列表距离上次刷新超过5分钟，则自动刷新一下
        var lastAutoRefreshdate = Date()
        NotificationCenter.default.rx
            .notification(UIApplication.willEnterForegroundNotification)
            .filter { _ in
                let now = Date()
                if now.timeIntervalSince1970 - lastAutoRefreshdate.timeIntervalSince1970 > 60 * 5 {
                    lastAutoRefreshdate = now
                    return true
                }
                return false
            }
            .subscribe(onNext: { [weak self] _ in
                self?.tableView.refreshControl?.sendActions(for: .valueChanged)
            }).disposed(by: rx.disposeBag)
    }

    // tableView 数据源
    private lazy var dataSource = RxTableViewSectionedAnimatedDataSource<MessageSection>(
        animationConfiguration: AnimationConfiguration(
            insertAnimation: .none,
            reloadAnimation: .none,
            deleteAnimation: .left
        ),
        configureCell: { _, tableView, _, item -> UITableViewCell in
            
            switch item {
            case .message(let message):
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(MessageTableViewCell.self)") as? MessageTableViewCell else {
                    return UITableViewCell()
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
                cell.cellData = (title, max(0, totalCount - messages.count), messages)
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
        
        let itemSelected = tableView.rx.itemSelected.asDriver().compactMap { [weak self] indexPath -> Int? in
            guard let self else { return nil }
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
                    return nil
                }
            }
            
            return indexPath.row
        }
        
        let output = viewModel.transform(
            input: MessageListViewModel.Input(
                refresh: tableView.refreshControl!.rx.controlEvent(.valueChanged).asDriver(),
                loadMore: tableView.mj_footer!.rx.refresh.asDriver(),
                itemDelete: tableView.rx.modelDeleted(MessageListCellItem.self).asDriver(),
                itemSelected: itemSelected,
                delete: getBatchDeleteDriver(),
                groupToggleTap: groupBtn.rx.tap.asDriver(),
                searchText: navigationItem.searchController!.searchBar.rx.text.asObservable()
            ))
        
        // tableView 刷新状态
        output.refreshAction
            .drive(tableView.rx.refreshAction)
            .disposed(by: rx.disposeBag)
        
        output.messages
            .drive(tableView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)
        
        // message操作alert
        output.alertMessage.drive(onNext: { [weak self] message in
            self?.alertMessage(message: message.0, indexPath: IndexPath(row: message.1, section: 0))
        }).disposed(by: rx.disposeBag)
        
        // 选择群组
        output.type
            .drive(onNext: { [weak self] type in
                (self?.groupButton.customView as? UIButton)?.isSelected = type == .group
            }).disposed(by: rx.disposeBag)
        
        // 标题
        output.title
            .drive(self.navigationItem.rx.title).disposed(by: rx.disposeBag)
    }
    
    private func getBatchDeleteDriver() -> Driver<MessageDeleteType> {
        guard let deleteBtn = deleteButton.customView as? BKButton else {
            return Driver.never()
        }
        return deleteBtn.rx
            .tap
            .flatMapLatest { _ -> PublishRelay<MessageDeleteType> in
                let relay = PublishRelay<MessageDeleteType>()
                
                func alert(_ type: MessageDeleteType) {
                    let alertController = UIAlertController(title: nil, message: "\(NSLocalizedString("clearFrom"))\n\(type.string)", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("clear"), style: .destructive, handler: { _ in
                        relay.accept(type)
                    }))
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: .cancel, handler: nil))
                    self.navigationController?.present(alertController, animated: true, completion: nil)
                }
                
                let alertController = UIAlertController(title: nil, message: NSLocalizedString("clearFrom"), preferredStyle: .actionSheet)
                alertController.addAction(UIAlertAction(title: NSLocalizedString("lastHour"), style: .default, handler: { _ in
                    alert(.lastHour)
                }))
                alertController.addAction(UIAlertAction(title: NSLocalizedString("today"), style: .default, handler: { _ in
                    alert(.today)
                }))
                alertController.addAction(UIAlertAction(title: NSLocalizedString("todayAndYesterday"), style: .default, handler: { _ in
                    alert(.todayAndYesterday)
                }))
                alertController.addAction(UIAlertAction(title: NSLocalizedString("allTime"), style: .default, handler: { _ in
                    alert(.allTime)
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
                
                return relay
            }
            .asDriver(onErrorDriveWith: .empty())
    }
    
    private func alertMessage(message: String, indexPath: IndexPath) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let copyAction = UIAlertAction(title: NSLocalizedString("CopyAll"), style: .default, handler: { [weak self]
            (_: UIAlertAction) in
                UIPasteboard.general.string = message
                self?.showSnackbar(text: NSLocalizedString("Copy"))
        })
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel"), style: .cancel, handler: { _ in })
        
        alertController.addAction(copyAction)
        alertController.addAction(cancelAction)
        if UIDevice.current.userInterfaceIdiom == .pad {
            if let cell = self.tableView.cellForRow(at: indexPath) {
                alertController.popoverPresentationController?.sourceView = self.tableView
                alertController.popoverPresentationController?.sourceRect = cell.frame
                alertController.modalPresentationStyle = .popover
            }
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
            
            if let cell = self.tableView.cellForRow(at: indexPath) as? MessageTableViewCell {
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
}
