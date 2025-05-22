//
//  ViewController.swift
//  Bark
//
//  Created by huangfeng on 2018/3/7.
//  Copyright © 2018年 Fin. All rights reserved.
//

import Material
import RxCocoa
import RxDataSources
import RxSwift
import UIKit
import UserNotifications

class HomeViewController: BaseViewController<HomeViewModel> {
    let newButton: BKButton = {
        let btn = BKButton()
        btn.setImage(Icon.add, for: .normal)
        btn.imageView?.tintColor = BKColor.grey.darken4
        btn.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        return btn
    }()
    
    let serversButton: BKButton = {
        let btn = BKButton()
        btn.setImage(UIImage(named: "baseline_filter_drama_black_24pt"), for: .normal)
        btn.imageView?.tintColor = BKColor.grey.darken4
        btn.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        return btn
    }()
    
    let startButton: FABButton = {
        let button = FABButton(title: NSLocalizedString("RegisterDevice"))
        button.backgroundColor = BKColor.grey.lighten5
        button.transition([.scale(0.75), .opacity(0)])
        return button
    }()
        
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.backgroundColor = BKColor.background.primary
        tableView.register(PreviewCardCell.self, forCellReuseIdentifier: "\(PreviewCardCell.self)")
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        return tableView
    }()
    
    override func makeUI() {
        self.view.backgroundColor = BKColor.background.primary
        
        navigationItem.setBarButtonItems(items: [
            UIBarButtonItem(customView: newButton),
            UIBarButtonItem(customView: serversButton)
        ], position: .right)
        
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { make in
            make.top.right.bottom.left.equalToSuperview()
        }
        
        self.view.addSubview(self.startButton)
        self.startButton.snp.makeConstraints { make in
            make.width.height.equalTo(150)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-50)
        }
        
        Client.shared.currentTabBarController?
            .tabBarItemDidClick
            .filter { $0 == .service }
            .subscribe(onNext: { [weak self] _ in
                self?.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            }).disposed(by: self.rx.disposeBag)
    }

    override func bindViewModel() {
        // 第一次进入APP 查看通知权限设置
        let authorizationStatus = Single<UNAuthorizationStatus>.create { single -> Disposable in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                single(.success(settings.authorizationStatus))
            }
            return Disposables.create()
        }
        
        // 请求通知权限操作
        let startRequestAuthorization: () -> Observable<Bool> = {
            Single<Bool>.create { single -> Disposable in
                let center = UNUserNotificationCenter.current()
                center.requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert], completionHandler: { (_ granted: Bool, _: Error?) in
                    single(.success(granted))
                })
                return Disposables.create()
            }
            .asObservable()
        }
        
        let output = viewModel.transform(
            input: HomeViewModel.Input(
                addCustomServerTap: newButton.rx.tap.asDriver(),
                serverListTap: serversButton.rx.tap.asDriver(),
                viewDidAppear: self.rx.methodInvoked(#selector(viewDidAppear(_:)))
                    .map { _ in () }
                    .asDriver(onErrorDriveWith: .empty()),
                start: self.startButton.rx.tap.asDriver(),
                clientState: Client.shared.state.asDriver(),
                authorizationStatus: authorizationStatus,
                startRequestAuthorizationCreator: startRequestAuthorization
            )
        )
        
        let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, PreviewCardCellViewModel>> { _, tableView, _, item -> UITableViewCell in
            if let cell = tableView.dequeueReusableCell(withIdentifier: "\(PreviewCardCell.self)") as? PreviewCardCell {
                cell.bindViewModel(model: item)
                return cell
            }
            return UITableViewCell()
        }
        
        // 标题
        output.title
            .drive(self.navigationItem.rx.title)
            .disposed(by: rx.disposeBag)
        
        // TableView数据源
        output.previews
            .drive(self.tableView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)
        
        // 跳转到对应页面
        output.push
            .drive(onNext: { [weak self] viewModel in
                self?.pushViewModel(viewModel: viewModel)
            })
            .disposed(by: rx.disposeBag)
        output.present
            .drive(onNext: { [weak self] viewModel in
                self?.presentViewModel(viewModel: viewModel)
            })
            .disposed(by: rx.disposeBag)
        
        // 通过ping服务器，判断 clienState
        output.clienStateChanged
            .drive(Client.shared.state)
            .disposed(by: rx.disposeBag)
        
        // 根据通知权限，设置是否隐藏注册按钮、显示示例预览列表
        output.tableViewHidden
            .map { !$0 }
            .drive(self.tableView.rx.isHidden)
            .disposed(by: rx.disposeBag)
        output.tableViewHidden
            .drive(self.startButton.rx.isHidden)
            .disposed(by: rx.disposeBag)
        
        // 注册推送
        output.registerForRemoteNotifications.drive(onNext: {
            UIApplication.shared.registerForRemoteNotifications()
        })
        .disposed(by: rx.disposeBag)
        
        // 弹出提示
        output.showSnackbar
            .drive(onNext: { [weak self] text in
                self?.showSnackbar(text: text)
            })
            .disposed(by: rx.disposeBag)
        
        // 弹出服务器错误提示，引导用户跳转FAQ
        output.alertServerError
            .drive(onNext: { [weak self] error in
                self?.alertServerError(error: error)
            })
            .disposed(by: rx.disposeBag)
        
        // startButton是否可点击
        output.startButtonEnable
            .drive(self.startButton.rx.isEnabled)
            .disposed(by: rx.disposeBag)
        
        // 复制文本
        output.copy
            .drive(onNext: { [weak self] text in
                UIPasteboard.general.string = text
                self?.showSnackbar(text: NSLocalizedString("Copy"))
            })
            .disposed(by: rx.disposeBag)
        
        // 预览
        output.preview
            .drive(onNext: { url in
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            })
            .disposed(by: rx.disposeBag)
        
        // 原样刷新 TableView
        output.reloadData
            .drive(onNext: { [weak self] in
                self?.tableView.reloadData()
            })
            .disposed(by: rx.disposeBag)
    }
    
    func pushViewModel(viewModel: ViewModel) {
        var viewController: UIViewController?
        if let viewModel = viewModel as? NewServerViewModel {
            viewController = NewServerViewController(viewModel: viewModel)
        } else if let viewModel = viewModel as? SoundsViewModel {
            viewController = SoundsViewController(viewModel: viewModel)
        } else if let viewModel = viewModel as? CryptoSettingViewModel {
            self.navigationController?.present(BarkNavigationController(rootViewController: CryptoSettingController(viewModel: viewModel)), animated: true)
            return
        }
        if let viewController = viewController {
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    func presentViewModel(viewModel: ViewModel) {
        if let viewModel = viewModel as? ServerListViewModel {
            let controller = BarkSnackbarController(
                rootViewController: BarkNavigationController(
                    rootViewController: ServerListViewController(viewModel: viewModel)))
            self.navigationController?.present(controller, animated: true, completion: nil)
        }
    }
    
    func alertServerError(error: String) {
        let alertController = UIAlertController(title: NSLocalizedString("ServerError"), message: error, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("faq"), style: .default, handler: { [weak self] _ in
            guard let url = try? NSLocalizedString("faqUrl").asURL() else {
                return
            }
            self?.navigationController?.present(BarkSFSafariViewController(url: url), animated: true, completion: nil)
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
}
