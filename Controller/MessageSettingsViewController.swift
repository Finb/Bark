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
        tableView.register(DetailTextCell.self, forCellReuseIdentifier: "\(DetailTextCell.self)")
        tableView.register(SpacerCell.self, forCellReuseIdentifier: "\(SpacerCell.self)")
        
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
        let output = viewModel.transform(
            input: MessageSettingsViewModel.Input(
                itemSelected: self.tableView.rx.modelSelected(MessageSettingItem.self).asDriver()
            )
        )
        
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
            case let .detail(title,text,textColor,_):
                if let cell = tableView.dequeueReusableCell(withIdentifier: "\(DetailTextCell.self)") as? DetailTextCell {
                    cell.textLabel?.text = title
                    cell.detailTextLabel?.text = text
                    cell.detailTextLabel?.textColor = textColor
                    return cell
                }
            case let .spacer(height, color):
                if let cell = tableView.dequeueReusableCell(withIdentifier: "\(SpacerCell.self)") as? SpacerCell {
                    cell.height = height
                    cell.backgroundColor = color
                    return cell
                }
            }
            
            return UITableViewCell()
        }
        
        output.settings
            .drive(tableView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)
     
        output.openUrl.drive {[weak self] url in
            self?.navigationController?.present(BarkSFSafariViewController(url: url), animated: true, completion: nil)
        }.disposed(by: rx.disposeBag)

    }

}
