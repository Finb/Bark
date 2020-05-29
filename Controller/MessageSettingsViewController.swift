//
//  MessageSettingsViewController.swift
//  Bark
//
//  Created by huangfeng on 2020/5/28.
//  Copyright © 2020 Fin. All rights reserved.
//

import UIKit
import Material
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
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("settings")
        
        self.view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        } 
    }

}

extension MessageSettingsViewController: UITableViewDelegate,UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "\(LabelCell.self)") as! LabelCell
            cell.textLabel?.text = "iCloud"
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "\(iCloudStatusCell.self)") as! iCloudStatusCell
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "\(LabelCell.self)") as! LabelCell
            cell.textLabel?.text = NSLocalizedString("iCloudSync")
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "\(LabelCell.self)") as! LabelCell
            cell.textLabel?.text = NSLocalizedString("defaultArchiveSettings")
            return cell
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: "\(ArchiveSettingCell.self)") as! ArchiveSettingCell
            return cell
        case 5:
            let cell = tableView.dequeueReusableCell(withIdentifier: "\(LabelCell.self)") as! LabelCell
            cell.textLabel?.text = NSLocalizedString("archiveNote")
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    
}
