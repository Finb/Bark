//
//  ViewController.swift
//  Bark
//
//  Created by huangfeng on 2018/3/7.
//  Copyright © 2018年 Fin. All rights reserved.
//

import UIKit
import UserNotifications
import Material
import RxCocoa
import RxDataSources

class HomeViewController: BaseViewController {
    
    let newButton: BKButton = {
        let btn = BKButton()
        btn.setImage(Icon.add, for: .normal)
        btn.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        return btn
    }()
    
    let historyMessageButton: BKButton = {
        let btn = BKButton()
        btn.setImage(Icon.history, for: .normal)
        btn.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        return btn
    }()
    
    let startButton: FABButton = {
        let button = FABButton(title: NSLocalizedString("RegisterDevice"))
        button.backgroundColor = Color.white
        button.transition([ .scale(0.75) , .opacity(0)] )
        return button
    }()
        
    let tableView :UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.backgroundColor = Color.grey.lighten3
        tableView.register(PreviewCardCell.self, forCellReuseIdentifier: "\(PreviewCardCell.self)")
        return tableView
    }()
    
    override func makeUI() {
        self.view.backgroundColor = Color.grey.lighten3
        
        navigationItem.setRightBarButtonItem(
            item: UIBarButtonItem(customView: newButton))
        navigationItem.setLeftBarButtonItem(
            item: UIBarButtonItem(customView: historyMessageButton))
        
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (make ) in
            make.top.right.bottom.left.equalToSuperview()
        }
        
        self.view.addSubview(self.startButton)
        self.startButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(150)
            make.centerX.equalToSuperview()
            make.top.equalTo(150)
        }
        
    }
    override func bindViewModel() {
        guard let viewModel = self.viewModel as? HomeViewModel else {
            return
        }
            
        let output = viewModel.transform(
            input: HomeViewModel.Input(
                addCustomServerTap: newButton.rx.tap.asDriver(),
                historyMessageTap: historyMessageButton.rx.tap.asDriver(),

                viewDidAppear: self.rx.methodInvoked(#selector(viewDidAppear(_:)))
                    .map{ _ in () }
                    .asDriver(onErrorDriveWith: .empty()),
                start: self.startButton.rx.tap.asDriver()
            )
        )
        
        let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String,PreviewCardCellViewModel>> { (source, tableView, indexPath, item) -> UITableViewCell in
            if let cell = tableView.dequeueReusableCell(withIdentifier: "\(PreviewCardCell.self)") as? PreviewCardCell{
                cell.bindViewModel(model: item)
                return cell
            }
            return UITableViewCell()
        }
        
        output.title
            .drive(self.navigationItem.rx.title)
            .disposed(by: rx.disposeBag)
        
        output.previews
            .drive(self.tableView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)
        
        output.push.drive(onNext: {[weak self] viewModel in
            self?.pushViewModel(viewModel: viewModel)
        }).disposed(by: rx.disposeBag)
        
        output.clienState.drive(onNext: {[weak self] state in
            Client.shared.state = state
            self?.refreshState()
        }).disposed(by: rx.disposeBag)
        
        output.tableViewHidden
            .map{ !$0 }
            .drive(self.tableView.rx.isHidden)
            .disposed(by: rx.disposeBag)
        output.tableViewHidden
            .drive(self.startButton.rx.isHidden)
            .disposed(by: rx.disposeBag)
        
        output.showSnackbar
            .drive(onNext: {[weak self] text in
                self?.showSnackbar(text: text)
            })
            .disposed(by: rx.disposeBag)
        
        output.startButtonEnable
            .drive(self.startButton.rx.isEnabled)
            .disposed(by: rx.disposeBag)
        
        output.copy.drive(onNext: {[weak self] text in
            UIPasteboard.general.string = text
            self?.showSnackbar(text: NSLocalizedString("Copy"))
        })
        .disposed(by: rx.disposeBag)
        
        output.preview.drive(onNext: { url in
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        })
        .disposed(by: rx.disposeBag)
        
    }
    
    func pushViewModel(viewModel:ViewModel) {
        var viewController:UIViewController?
        if let viewModel = viewModel as? NewServerViewModel {
            viewController = NewServerViewController(viewModel: viewModel)
        }
        else if let viewModel = viewModel as? MessageListViewModel {
            viewController = MessageListViewController(viewModel: viewModel)
        }
        else if let viewModel = viewModel as? SoundsViewModel {
            viewController = SoundsViewController(viewModel: viewModel)
        }
        
        if let viewController = viewController {
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
}

extension HomeViewController {
    @objc func refreshState() {
        switch Client.shared.state {
        case .ok:
            if let url = URL(string: ServerManager.shared.currentAddress) {
                if url.scheme?.lowercased() != "https" {
                    self.showSnackbar(text: NSLocalizedString("InsecureConnection"))
                }
                self.tableView.reloadData()
            }
        case .serverError:
            self.showSnackbar(text: NSLocalizedString("ServerError"))
        default: break;
        }
    }
}
