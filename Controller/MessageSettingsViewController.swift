//
//  MessageSettingsViewController.swift
//  Bark
//
//  Created by huangfeng on 2020/5/28.
//  Copyright © 2020 Fin. All rights reserved.
//

import UIKit
import Material
import RxDataSources
class MessageSettingsViewController: BaseViewController {
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.backgroundColor = Color.grey.lighten5
        tableView.register(LabelCell.self, forCellReuseIdentifier: "\(LabelCell.self)")
        tableView.register(iCloudStatusCell.self, forCellReuseIdentifier: "\(iCloudStatusCell.self)")
        tableView.register(ArchiveSettingCell.self, forCellReuseIdentifier: "\(ArchiveSettingCell.self)")
        
        return tableView
    }()
    override func makeUI() {
        self.title = NSLocalizedString("settings")
        
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    override func bindViewModel() {
        guard let viewModel = self.viewModel as? MessageSettingsViewModel else {
            return
        }
        let output = viewModel.transform(input: MessageSettingsViewModel.Input())
        
        let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, MessageSettingItem>> { (source, tableView, indexPath, item) -> UITableViewCell in
            switch item {
            case .label(let text):
                if let cell = tableView.dequeueReusableCell(withIdentifier: "\(LabelCell.self)") as? LabelCell {
                    cell.textLabel?.text = text
                    return cell
                }
            case .iCloudStatus:
                if let cell = tableView.dequeueReusableCell(withIdentifier: "\(iCloudStatusCell.self)") {
                    return cell
                }
            case .archiveSetting(let viewModel):
                if let cell = tableView.dequeueReusableCell(withIdentifier: "\(ArchiveSettingCell.self)") as? ArchiveSettingCell {
                    cell.bindViewModel(model: viewModel)
                    return cell
                }
            }
            return UITableViewCell()
        }
        
        output.settings
            .drive(tableView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)
        
    }

}
