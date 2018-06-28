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
class HomeViewController: BaseViewController {
    
    let newButton: IconButton = {
        let btn = IconButton(image: Icon.add, tintColor: .white)
        btn.pulseColor = .white
        return btn
    }()
    
    let startButton = FABButton(title: NSLocalizedString("RegisterDevice"))
    
    let statusButton = IconButton(image: UIImage(named: "baseline_https_black_24pt"), tintColor: .white)
    
    let tableView :UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.backgroundColor = Color.grey.lighten3
        tableView.register(PreviewCardCell.self, forCellReuseIdentifier: "\(PreviewCardCell.self)")
        return tableView
    }()
    
    var dataSource:[PreviewModel] = {
        return [
            PreviewModel(
                body: NSLocalizedString("CustomedNotifictionContent"),
                notice: NSLocalizedString("Notice1")),
            PreviewModel(
                title: NSLocalizedString("CustomedNotifictionTitle"),
                body: NSLocalizedString("CustomedNotifictionContent"),
                notice: NSLocalizedString("Notice2"))
        ]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = Color.grey.lighten3
        
        navigationItem.titleLabel.textColor = .white
        navigationItem.titleLabel.textAlignment = .left
        navigationItem.detailLabel.textAlignment = .left
        navigationItem.detailLabel.textColor = .white
        
        newButton.addTarget(self, action: #selector(new), for: .touchUpInside)
        navigationItem.rightViews = [newButton]
        navigationItem.leftViews = [statusButton]

        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (make ) in
            make.top.right.bottom.left.equalToSuperview()
        }
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            if settings.authorizationStatus != .authorized {
                dispatch_sync_safely_main_queue {
                    self.startButton.transition([ .scale(0.75) , .opacity(0)] )
                    self.startButton.addTarget(self, action: #selector(self.start), for: .touchUpInside)
                    self.view.addSubview(self.startButton)
                    self.startButton.snp.makeConstraints { (make) in
                        make.width.height.equalTo(150)
                        make.centerX.equalToSuperview()
                        make.top.equalTo(150)
                    }
                    self.tableView.isHidden = true
                }
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(refreshState), name: Notification.Name(rawValue: "ClientStateChangeds"), object: nil)
    }
    override func viewWillAppear(_ animated: Bool) {
        if let url = URL(string: ServerManager.shared.currentAddress) {
            navigationItem.titleLabel.text = url.host
            refreshState()
        }
    }
}

extension HomeViewController : UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "\(PreviewCardCell.self)", for: indexPath) as! PreviewCardCell
        cell.bind(model: dataSource[indexPath.row])
        cell.copyHandler = {[weak self] in
            self?.showSnackbar(text: NSLocalizedString("Copy"))
        }
        return cell
    }
}

extension HomeViewController {
    @objc func new(){
        self.navigationController?.pushViewController(NewServerViewController(), animated: true)
    }
    
    @objc func start(){
        startButton.titleColor = Color.grey.base
        startButton.isEnabled = false
        
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert , .sound , .badge], completionHandler: {(_ granted: Bool, _ error: Error?) -> Void in
            
            // 兼容 iOS 12 BUG，不这样写会UI卡死
            DispatchQueue.global(qos: .default).async {
                DispatchQueue.main.sync {
                    if granted {
                        UIApplication.shared.registerForRemoteNotifications()
                        if self.tableView.isHidden{
                            self.tableView.isHidden = false
                        }
                        self.startButton.removeFromSuperview()
                    }
                    else{
                        self.showSnackbar(text: NSLocalizedString("AllowNotifications"))
                        self.startButton.titleColor = Color.blue.base
                        self.startButton.isEnabled = true
                    }
                }
            }
            
        })
    }
    
    @objc func refreshState() {
        switch Client.shared.state {
        case .ok:
            if let url = URL(string: ServerManager.shared.currentAddress) {
                if url.scheme?.lowercased() == "https" {
                    navigationItem.detailLabel.text = NSLocalizedString("SecureConnection")
                    statusButton.image = UIImage(named: "baseline_https_black_24pt")
                }
                else {
                    navigationItem.detailLabel.text = NSLocalizedString("InsecureConnection")
                    statusButton.image = UIImage(named: "baseline_http_black_24pt")
                }
                self.tableView.reloadData()
            }
        case .unRegister:
            navigationItem.detailLabel.text = NSLocalizedString("UnregisteredDevice")
        case .serverError:
            navigationItem.detailLabel.text = NSLocalizedString("ServerError")
        }
    }
}
