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
        let btn = IconButton(image: Icon.add, tintColor: .black)
        btn.pulseColor = .black
        btn.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        return btn
    }()
    
    lazy var startButton = FABButton(title: NSLocalizedString("RegisterDevice"))
    
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
                body: NSLocalizedString("CustomedNotificationContent"),
                notice: NSLocalizedString("Notice1")),
            PreviewModel(
                title: NSLocalizedString("CustomedNotificationTitle"),
                body: NSLocalizedString("CustomedNotificationContent"),
                notice: NSLocalizedString("Notice2")),
            PreviewModel(
                body: NSLocalizedString("archiveNotificationMessageTitle"),
                notice: NSLocalizedString("archiveNotificationMessage"),
                queryParameter: "isArchive=1"
                ),
            PreviewModel(
                body: "URL Test",
                notice: NSLocalizedString("urlParameter"),
                queryParameter: "url=https://www.baidu.com"
                ),
            PreviewModel(
                body: "Copy Test",
                notice: NSLocalizedString("copyParameter"),
                queryParameter: "copy=test",
                image: UIImage(named: "copyTest")
            ),
            PreviewModel(
                body: NSLocalizedString("automaticallyCopyTitle"),
                notice: NSLocalizedString("automaticallyCopy"),
                queryParameter: "automaticallyCopy=1&copy=optional"
            )
        ]
    }()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _ = BarkApi.provider.request(.ping(baseURL: ServerManager.shared.currentAddress))
            .filterResponseError()
            .subscribe(
                onNext: { _ in
                    Client.shared.state = .ok
                },
                onError: { _ in
                    Client.shared.state = .serverError
            })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = Color.grey.lighten3

        newButton.addTarget(self, action: #selector(new), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: newButton)
        
        let messageBtn = IconButton(image: Icon.history, tintColor: .black)
        messageBtn.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        messageBtn.addTarget(self, action: #selector(history), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: messageBtn)

        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (make ) in
            make.top.right.bottom.left.equalToSuperview()
        }
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            if settings.authorizationStatus != .authorized {
                dispatch_sync_safely_main_queue {
                    self.startButton.backgroundColor = Color.white
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
            navigationItem.title = url.host
            refreshState()
        }
    }
    
}

extension HomeViewController : UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "\(indexPath.row)") as? PreviewCardCell{
            cell.bind(model: dataSource[indexPath.row])
            return cell
        }
        let cell = PreviewCardCell(style: .default, reuseIdentifier: "\(indexPath.row)", model:dataSource[indexPath.row])
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
    @objc func history(){
        self.navigationController?.pushViewController(MessageListViewController(), animated: true)
    }
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
