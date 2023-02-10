//
//  GroupFilterViewController.swift
//  Bark
//
//  Created by huangfeng on 2021/6/8.
//  Copyright © 2021 Fin. All rights reserved.
//

import Material
import MJRefresh
import RealmSwift
import RxCocoa
import RxDataSources
import RxSwift
import UIKit

class GroupFilterViewController: BaseViewController<GroupFilterViewModel> {
    let doneButton: BKButton = {
        let btn = BKButton()
        btn.setTitle(NSLocalizedString("done"), for: .normal)
        btn.setTitleColor(BKColor.lightBlue.darken3, for: .normal)
        btn.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        btn.fontSize = 14
        return btn
    }()
    
    let showAllGroupsButton: BKButton = {
        let btn = BKButton()
        btn.setTitle(NSLocalizedString("hideAllGroups"), for: .selected)
        btn.setTitle(NSLocalizedString("showAllGroups"), for: .normal)
        btn.setTitleColor(Color.lightBlue.darken3, for: .normal)
        btn.fontSize = 14
        return btn
    }()
    
    let tableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: .insetGrouped)
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = BKColor.grey.lighten3
        tableView.backgroundColor = BKColor.background.primary
        tableView.register(GroupTableViewCell.self, forCellReuseIdentifier: "\(GroupTableViewCell.self)")
        return tableView
    }()
    
    override func makeUI() {
        self.title = NSLocalizedString("group")
        self.navigationItem.setRightBarButtonItem(item: UIBarButtonItem(customView: doneButton))
        
        self.view.addSubview(tableView)
        self.view.addSubview(showAllGroupsButton)
        tableView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().offset((kSafeAreaInsets.bottom + 40) * -1)
            make.left.right.equalToSuperview()
        }
        showAllGroupsButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.height.equalTo(40)
            make.bottom.equalToSuperview().offset(-kSafeAreaInsets.bottom)
        }
        
        self.tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: 20))
    }

    override func bindViewModel() {
        let output = viewModel.transform(
            input: GroupFilterViewModel.Input(
                showAllGroups: self.showAllGroupsButton.rx
                    .tap
                    .compactMap { [weak self] in
                        guard let strongSelf = self else { return nil }
                        return !strongSelf.showAllGroupsButton.isSelected
                    }
                    .asDriver(onErrorDriveWith: .empty()),
                doneTap: self.doneButton.rx.tap.asDriver()
            ))
        
        let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, GroupCellViewModel>> { _, tableView, _, item -> UITableViewCell in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(GroupTableViewCell.self)") as? GroupTableViewCell else {
                return UITableViewCell()
            }
            cell.bindViewModel(model: item)
            return cell
        }
        
        output.groups
            .drive(tableView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)
        
        output.isShowAllGroups
            .drive(self.showAllGroupsButton.rx.isSelected)
            .disposed(by: rx.disposeBag)
        
        output.dismiss.drive(onNext: { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        })
        .disposed(by: rx.disposeBag)
    }
}

extension GroupFilterViewController: UITableViewDelegate {}
