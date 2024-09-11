//
//  SectionTableViewController-iPad.swift
//  Bark
//
//  Created by sidguan on 2024/6/23.
//  Copyright © 2024 Fin. All rights reserved.
//

import UIKit

import NSObject_Rx
import RxCocoa
import RxDataSources
import RxSwift

class SectionViewController_iPad: BaseViewController<SectionViewModel>, UITableViewDelegate {
    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "\(UITableViewCell.self)")
        tableView.backgroundColor = BKColor.background.primary
        return tableView
    }()
    
    let homeController = BarkNavigationController(rootViewController: HomeViewController(viewModel: HomeViewModel()))
    let messageListController = BarkNavigationController(rootViewController: MessageListViewController(viewModel: MessageListViewModel()))
    let settingsController = BarkNavigationController(rootViewController: MessageSettingsViewController(viewModel: MessageSettingsViewModel()))
    
    var viewControllers: [UIViewController] {
        [
            homeController,
            messageListController,
            settingsController
        ]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Bark"
        navigationItem.largeTitleDisplayMode = .automatic
    }
    
    override func makeUI() {
        self.view.addSubview(tableView)
        tableView.delegate = self
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        tableView.rx
            .itemSelected
            .flatMapLatest { indexPath -> Observable<IndexPath> in
                return Observable.just(indexPath)
            }
            .subscribe { [weak self] indexPath in
                guard let self, indexPath.row < self.viewControllers.count else {
                    return
                }
                self.splitViewController?.showDetailViewController(self.viewControllers[indexPath.row], sender: self)
                Settings[.selectedViewControllerIndex] = indexPath.row
            }.disposed(by: rx.disposeBag)
    }
    
    override func bindViewModel() {
        let output = viewModel.transform(input: SectionViewModel.Input())
        let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, SectionItem>> {
            _, tableView, _, item -> UITableViewCell in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(UITableViewCell.self)") else {
                return UITableViewCell()
            }
            cell.selectionStyle = .gray
            cell.imageView?.image = item.image
            cell.imageView?.tintColor = BKColor.grey.darken4
            cell.textLabel?.text = item.title
            return cell
        }
        output.items
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }

    func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool {
        // 去掉额外的蓝色 selectionStyle
        return false
    }
}
