//
//  MessageListViewController.swift
//  Bark
//
//  Created by huangfeng on 2020/5/25.
//  Copyright © 2020 Fin. All rights reserved.
//

import UIKit
import Material
import RealmSwift
import RxCocoa
import RxDataSources
import MJRefresh

class MessageListViewController: BaseViewController {
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.backgroundColor = Color.grey.lighten5
        tableView.register(MessageTableViewCell.self, forCellReuseIdentifier: "\(MessageTableViewCell.self)")
        return tableView
    }()
    
    let settingButton: BKButton = {
        let settingButton = BKButton()
        settingButton.setImage(Icon.settings, for: .normal)
        settingButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        return settingButton
    }()
    
    deinit {
        print("message list deinit")
    }
    
    override func makeUI() {
        self.title = NSLocalizedString("historyMessage")
        navigationItem.setRightBarButtonItem(item: UIBarButtonItem(customView: settingButton))
        
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        tableView.rx.setDelegate(self).disposed(by: rx.disposeBag)
        tableView.mj_footer = MJRefreshAutoFooter()
    }
    
    override func bindViewModel() {
        guard let viewModel = self.viewModel as? MessageListViewModel else {
            return
        }
        
        let output = viewModel.transform(input: MessageListViewModel.Input(
            settingClick: self.settingButton.rx.tap.asDriver(),
            loadMore: tableView.mj_footer!.rx.refresh.asDriver(),
            itemDelete: tableView.rx.itemDeleted.asDriver(),
            itemSelected: tableView.rx.modelSelected(MessageTableViewCellViewModel.self).asDriver()
        ))
        
        //跳转到设置界面
        output.settingClick
            .drive(onNext: {[weak self] viewModel in
                self?.navigationController?
                    .pushViewController(MessageSettingsViewController(viewModel: viewModel),
                                        animated: true)
            })
            .disposed(by: rx.disposeBag)
        
        //tableView 刷新状态
        output.refreshAction
            .drive(tableView.rx.refreshAction)
            .disposed(by: rx.disposeBag)
        
        //tableView 数据源
        let dataSource = RxTableViewSectionedAnimatedDataSource<MessageSection>(
            animationConfiguration: AnimationConfiguration(
                insertAnimation: .none,
                reloadAnimation: .none,
                deleteAnimation: .left),
            configureCell:{ (source, tableView, indexPath, item) -> UITableViewCell in
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(MessageTableViewCell.self)") as? MessageTableViewCell else {
                    return UITableViewCell ()
                }
                cell.bindViewModel(model: item)
                return cell
            }, canEditRowAtIndexPath: { _, _ in
                return true
            })
        
        output.messages
            .drive(tableView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)
        
        //message操作alert
        output.alertMessage.drive(onNext: {[weak self] message in
            self?.alertMessage(message: message)
        }).disposed(by: rx.disposeBag)
        
        //点击message中的URL
        output.urlTap.drive(onNext: { url in
            if ["http","https"].contains(url.scheme?.lowercased() ?? ""){
                  Client.shared.currentNavigationController?.present(BarkSFSafariViewController(url: url), animated: true, completion: nil)
              }
              else{
                  UIApplication.shared.open(url, options: [:], completionHandler: nil)
              }
        }).disposed(by: rx.disposeBag)
        
    }
    
    func alertMessage(message:String)  {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let copyAction = UIAlertAction(title: NSLocalizedString("Copy2"), style: .default, handler: {[weak self]
            (alert: UIAlertAction) -> Void in
            UIPasteboard.general.string = message
            self?.showSnackbar(text: NSLocalizedString("Copy"))
        })
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel"), style: .cancel, handler: { _ in })
        
        alertController.addAction(copyAction)
        alertController.addAction(cancelAction)
        
        Client.shared.currentNavigationController?.present(alertController, animated: true, completion: nil)
    }

}

extension MessageListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .destructive, title: "删除") {[weak self] (action, sourceView, actionPerformed) in
            self?.tableView.dataSource?.tableView?(self!.tableView, commit: .delete, forRowAt: indexPath)
            actionPerformed(true)
        }

        let configuration = UISwipeActionsConfiguration(actions: [action])
        return configuration
    }
}
