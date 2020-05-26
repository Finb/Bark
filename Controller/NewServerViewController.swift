//
//  NewServerViewController.swift
//  Bark
//
//  Created by huangfeng on 2018/6/25.
//  Copyright © 2018 Fin. All rights reserved.
//

import UIKit
import Material
import SnapKit
import SafariServices
class NewServerViewController: BaseViewController {

    let addressTextField : TextField = {
        let textField = TextField()
        textField.keyboardType = .URL
        textField.placeholder = NSLocalizedString("ServerAddress")
        textField.detail = NSLocalizedString("ServerExample")
        textField.transition([ .scale(0.85) , .opacity(0)] )
        textField.detailLabel.transition([ .scale(0.85) , .opacity(0)] )
        return textField
    }()
    
    let noticeLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("DeploymentDocuments")
        label.textColor = Color.blue.base
        label.font = UIFont.systemFont(ofSize: 12)
        label.transition([ .scale(0.85) , .opacity(0), .translate(x: 50)] )
        return label
    }()
    
    let doneButton = IconButton(image: Icon.check, tintColor: .black)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString("AddServer")
        
        doneButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        doneButton.addTarget(self, action: #selector(done), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: doneButton)
        
        self.view.layout(addressTextField).top(kNavigationHeight + 40).left(10).right(10)
        
        self.view.addSubview(noticeLabel)
        noticeLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.addressTextField.snp.bottom).offset(40)
            make.left.equalTo(self.addressTextField)
        }
        noticeLabel.isUserInteractionEnabled = true
        noticeLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(noticeClick)))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if (addressTextField.text?.count ?? 0) <= 0 {
            _ = self.addressTextField.becomeFirstResponder()
            addressTextField.text = "https://"
        }
    }

    @objc func done(){
        self.addressTextField.resignFirstResponder()
        if let text = addressTextField.text, let _ = URL(string: text) {
            _ = BarkApi.provider.request(.ping(baseURL: text))
                .filterResponseError()
                .subscribe(onNext: {[weak self] (_) in
                    self?.navigationController?.popViewController(animated: true)
                    ServerManager.shared.currentAddress = text
                    self?.showSnackbar(text: NSLocalizedString("AddedSuccessfully"))
                    Client.shared.bindDeviceToken()
                    
                }, onError: {[weak self] (error) in
                    self?.showSnackbar(text: "\(NSLocalizedString("InvalidServer"))\(error.localizedDescription)")
                })
        }
        else{
            self.showSnackbar(text: NSLocalizedString("InvalidURL"))
        }
    }
    

    @objc func noticeClick(){
        self.navigationController?.present(BarkSFSafariViewController(url: URL(string: "https://day.app/2018/06/bark-server-document/")!), animated: true, completion: nil)
    }
}
