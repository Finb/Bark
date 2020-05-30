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

class MessageListViewController: BaseViewController {
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.backgroundColor = Color.grey.lighten5
        tableView.register(MessageTableViewCell.self, forCellReuseIdentifier: "cell")
        return tableView
    }()
    var results:Results<Message>?
    deinit {
        print("message list deinit")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("historyMessage")
        
        let settingButton = IconButton(image: Icon.settings, tintColor: .black)
        settingButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        settingButton.addTarget(self, action: #selector(settingClick), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: settingButton)
        
        self.view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        
        self.refresh()
    }
    
    @objc func settingClick (){
        self.navigationController?.pushViewController(MessageSettingsViewController(), animated: true)
    }
    
    func refresh() {
        if let realm = try? Realm() {
            results = realm.objects(Message.self).filter("isDeleted != true").sorted(byKeyPath: "createDate", ascending: false)
            self.tableView.reloadData()
        }
        else {
        }
        
    }
}

extension MessageListViewController: UITableViewDataSource,UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let results = results{
            return results.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! MessageTableViewCell
        cell.message = results![indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .destructive, title: "删除") {[weak self] (action, sourceView, actionPerformed) in
            if let realm = try? Realm() {
                try? realm.write {
                    let message = self?.results?[indexPath.row]
                    message?.isDeleted = true
                }
            }
            _ = self?.results?.dropFirst(indexPath.row)
            self?.tableView.performBatchUpdates({
                self?.tableView.deleteRows(at: [indexPath], with: .none)
            }, completion: nil)
            actionPerformed(true)
            
        }
        
        let configuration = UISwipeActionsConfiguration(actions: [action])
        return configuration
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let copyAction = UIAlertAction(title: NSLocalizedString("Copy2"), style: .default, handler: {[weak self]
            (alert: UIAlertAction) -> Void in
            if let message = self?.results?[indexPath.row] {
                var str:String = ""
                if let title = message.title {
                    str += "\(title)\n"
                }
                if let body = message.body {
                    str += "\(body)\n"
                }
                if let url = message.url {
                    str += "\(url)"
                }
                str = String(str.prefix(str.count - 1))
                
                UIPasteboard.general.string = str
                self?.showSnackbar(text: NSLocalizedString("Copy"))
            }
        })
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel"), style: .cancel, handler: {
            (alert: UIAlertAction) -> Void in
        })
        
        alertController.addAction(copyAction)
        alertController.addAction(cancelAction)
        
        Client.shared.currentNavigationController?.present(alertController, animated: true, completion: nil)
    }
}
