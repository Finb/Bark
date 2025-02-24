//
//  ServerListViewController.swift
//  Bark
//
//  Created by huangfeng on 2022/3/25.
//  Copyright © 2022 Fin. All rights reserved.
//

import Material
import RxCocoa
import RxDataSources
import RxSwift
import UIKit

enum ServerActionType {
    case select
    case copy
    case reset(key: String?)
    case delete
    case setName(name: String?)
}

func == (lhs: ServerActionType, rhs: ServerActionType) -> Bool {
    switch (lhs, rhs) {
    case (.copy, .copy),
         (.delete, .delete),
         (.select, .select):
        return true
    case (.reset(let a), .reset(let b)):
        return a == b
    default:
        return false
    }
}

class ServerListViewController: BaseViewController<ServerListViewModel> {
    let closeButton: BKButton = {
        let closeButton = BKButton()
        closeButton.setImage(UIImage(named: "baseline_keyboard_arrow_down_black_24pt")?.withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        closeButton.hitTestSlop = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        closeButton.tintColor = BKColor.grey.darken4
        return closeButton
    }()

    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.backgroundColor = BKColor.background.primary
        tableView.register(ServerListTableViewCell.self, forCellReuseIdentifier: "\(ServerListTableViewCell.self)")
        tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        return tableView
    }()

    override func makeUI() {
        self.title = NSLocalizedString("serverList")

        navigationItem.setRightBarButtonItem(item: UIBarButtonItem(customView: closeButton))

        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        closeButton.rx.tap.subscribe { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        } onError: { _ in
            
        }.disposed(by: rx.disposeBag)
    }

    override func bindViewModel() {
        let action = getServerAction()

        // 选择 server
        let selectServer = action.filter { $0.1 == ServerActionType.select }
            .map { $0.0 }.asDriver(onErrorDriveWith: .empty())
        
        // 复制 server
        let copyServer = action.filter { $0.1 == ServerActionType.copy }
            .map { $0.0 }.asDriver(onErrorDriveWith: .empty())

        // 删除 server
        let deleteServer = action.filter { $0.1 == ServerActionType.delete }
            .map { $0.0 }.asDriver(onErrorDriveWith: .empty())

        // 重置 server key
        let resetServer = action.compactMap { r -> (Server, String?)? in
            if case ServerActionType.reset(let key) = r.1 {
                return (r.0, key)
            }
            return nil
        }.asDriver(onErrorDriveWith: .empty())
        
        // 设置服务器名称
        let setServerName = action.compactMap { r -> (Server, String?)? in
            if case ServerActionType.setName(let name) = r.1 {
                return (r.0, name)
            }
            return nil
        }.asDriver(onErrorDriveWith: .empty())

        let output = viewModel.transform(input: ServerListViewModel.Input(
            selectServer: selectServer,
            copyServer: copyServer,
            deleteServer: deleteServer,
            resetServer: resetServer,
            setServerName: setServerName
        ))

        let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, ServerListTableViewCellViewModel>> { _, tableView, _, item -> UITableViewCell in
            if let cell = tableView.dequeueReusableCell(withIdentifier: "\(ServerListTableViewCell.self)") as? ServerListTableViewCell {
                cell.bindViewModel(model: item)
                return cell
            }
            return UITableViewCell()
        }

        // TableView数据源
        output.servers
            .drive(self.tableView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)

        // 复制文本
        output.copy
            .drive(onNext: { [weak self] text in
                UIPasteboard.general.string = text
                self?.showSnackbar(text: NSLocalizedString("Copy"))
            })
            .disposed(by: rx.disposeBag)

        // 弹出提示
        output.showSnackbar
            .drive(onNext: { [weak self] text in
                self?.showSnackbar(text: text)
            })
            .disposed(by: rx.disposeBag)
    }

    func getServerAction() -> Driver<(Server, ServerActionType)> {
        return tableView.rx
            .itemSelected
            .flatMapLatest { indexPath in
                let relay = PublishRelay<(Server, ServerActionType)>()
                guard let viewModel: ServerListTableViewCellViewModel = try? self.tableView.rx.model(at: indexPath) else {
                    return relay
                }

                let alertController = UIAlertController(title: nil, message: "\(URL(string: viewModel.server.address)?.host ?? "")", preferredStyle: .actionSheet)
                alertController.addAction(UIAlertAction(title: NSLocalizedString("copyAddressAndKey"), style: .default, handler: { _ in
                    relay.accept((viewModel.server, .copy))
                }))

                alertController.addAction(UIAlertAction(title: NSLocalizedString("resetKey"), style: .default, handler: { _ in
                    let alertController = UIAlertController(title: NSLocalizedString("resetKey"), message: NSLocalizedString("resetKeyDesc"), preferredStyle: .alert)
                    alertController.addTextField { textField in
                        textField.placeholder = NSLocalizedString("resetKeyPlaceholder")
                    }
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("confirm"), style: .default, handler: { _ in
                        relay.accept((viewModel.server, .reset(key: alertController.textFields?.first?.text)))
                    }))
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: .cancel, handler: nil))
                    self.navigationController?.present(alertController, animated: true, completion: nil)
                }))

                alertController.addAction(UIAlertAction(title: NSLocalizedString("setAsDefaultServer"), style: .default, handler: { _ in
                    relay.accept((viewModel.server, .select))
                }))
                
                alertController.addAction(UIAlertAction(title: NSLocalizedString("setServerName"), style: .default, handler: { _ in
                    let alertController = UIAlertController(title: NSLocalizedString("setServerName"), message: nil, preferredStyle: .alert)
                    alertController.addTextField { textField in
                        textField.text = viewModel.server.name
                    }
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("confirm"), style: .default, handler: { _ in
                        relay.accept((viewModel.server, .setName(name: alertController.textFields?.first?.text)))
                    }))
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: .cancel, handler: nil))
                    self.navigationController?.present(alertController, animated: true, completion: nil)
                }))
                
                alertController.addAction(UIAlertAction(title: NSLocalizedString("deleteServer"), style: .destructive, handler: { _ in

                    let alertController = UIAlertController(title: nil, message: NSLocalizedString("confirmDeleteServer"), preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("confirm"), style: .destructive, handler: { _ in
                        relay.accept((viewModel.server, .delete))
                    }))
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: .cancel, handler: nil))
                    self.navigationController?.present(alertController, animated: true, completion: nil)

                }))

                alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: .cancel, handler: nil))
                
                if UIDevice.current.userInterfaceIdiom == .pad {
                    if let cell = self.tableView.cellForRow(at: indexPath) {
                        alertController.popoverPresentationController?.sourceView = self.tableView
                        alertController.popoverPresentationController?.sourceRect = cell.frame
                        alertController.modalPresentationStyle = .popover
                    }
                }
                self.navigationController?.present(alertController, animated: true, completion: nil)

                return relay
            }.asDriver(onErrorDriveWith: .empty())
    }
}
