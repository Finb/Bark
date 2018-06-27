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
    
    let startButton = FABButton(title: "注册设备")
    
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
                body:"这里改成你自己的推送内容",
                notice: "点击右上角按钮可以复制测试URL、预览推送效果\nSafari有缓存，没收到推送时请刷新页面"),
            PreviewModel(
                title: "推送标题",
                body:"这里改成你自己的推送内容",
                notice: "推送标题的字号比推送内容粗一点")
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
            self?.showSnackbar(text: "复制成功")
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
                        self.showSnackbar(text: "绑定设备需要推送。请打开推送后重试")
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
                    navigationItem.detailLabel.text = "HTTPS安全连接"
                    statusButton.image = UIImage(named: "baseline_https_black_24pt")
                }
                else {
                    navigationItem.detailLabel.text = "连接不安全，请使用HTTPS安全连接"
                    statusButton.image = UIImage(named: "baseline_http_black_24pt")
                }
                self.tableView.reloadData()
            }
        case .unRegister:
            navigationItem.detailLabel.text = "设备未注册，不能使用推送服务"
        case .serverError:
            navigationItem.detailLabel.text = "服务器错误，不能使用推送服务"
        }
    }
}
