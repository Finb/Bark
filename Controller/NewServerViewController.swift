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
        textField.placeholder = "服务器地址"
        textField.detail = "输入服务器地址，例如: https://api.day.app"
        textField.transition([ .scale(0.85) , .opacity(0)] )
        textField.detailLabel.transition([ .scale(0.85) , .opacity(0)] )
        return textField
    }()
    
    let noticeLabel: UILabel = {
        let label = UILabel()
        label.text = "查看服务端部署教程"
        label.textColor = Color.blue.base
        label.font = UIFont.systemFont(ofSize: 12)
        label.transition([ .scale(0.85) , .opacity(0), .translate(x: 50)] )
        return label
    }()
    
    let doneButton = IconButton(image: Icon.check, tintColor: .white)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.titleLabel.text = "添加私有服务器"
        
        doneButton.addTarget(self, action: #selector(done), for: .touchUpInside)
        navigationItem.rightViews = [doneButton]
        
        self.view.layout(addressTextField).top(40).left(10).right(10)
        
        self.view.addSubview(noticeLabel)
        noticeLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.addressTextField.snp.bottom).offset(40)
            make.left.equalTo(self.addressTextField)
        }
        noticeLabel.isUserInteractionEnabled = true
        noticeLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(noticeClick)))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        _ = self.addressTextField.becomeFirstResponder()
        addressTextField.text = "https://"
    }

    @objc func done(){
        self.addressTextField.resignFirstResponder()
        if let text = addressTextField.text, let _ = URL(string: text) {
            _ = BarkApi.provider.request(.ping(baseURL: text))
                .filterResponseError()
                .subscribe(onNext: {[weak self] (_) in
                    self?.navigationController?.popViewController(animated: true)
                    ServerManager.shared.currentAddress = text
                    self?.showSnackbar(text: "修改成功!")
                    Client.shared.bindDeviceToken()
                    
                }, onError: {[weak self] (error) in
                    self?.showSnackbar(text: "填写的服务器无效，请重试!\(error.localizedDescription)")
                })
        }
        else{
            self.showSnackbar(text: "输入的URL好像不对劲!")
        }
    }
    

    @objc func noticeClick(){
        self.navigationController?.present(BarkSFSafariViewController(url: URL(string: "https://day.app/2018/06/bark-server-document/")!), animated: true, completion: nil)
    }
}
