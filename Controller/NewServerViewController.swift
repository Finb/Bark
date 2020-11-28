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
import RxSwift
import RxCocoa

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
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer())
        return label
    }()
    
    lazy var doneButton: BKButton = {
        let doneButton = BKButton()
        doneButton.setImage(Icon.check, for: .normal)
        doneButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        navigationItem.setRightBarButtonItem(item: UIBarButtonItem(customView: doneButton))
        return doneButton
    }()
    
    override func makeUI() {
        navigationItem.title = NSLocalizedString("AddServer")
        
        self.view.layout(addressTextField)
            .top(kNavigationHeight + 40).left(10).right(10)
        
        self.view.addSubview(noticeLabel)
        noticeLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.addressTextField.snp.bottom).offset(40)
            make.left.equalTo(self.addressTextField)
        }
    }
    override func bindViewModel() {
        guard let viewModel = self.viewModel as? NewServerViewModel else {
            return
        }
        let noticeTap = noticeLabel.gestureRecognizers!.first!.rx
            .event
            .map({ (_) -> () in
                return ()
            })
            .asDriver(onErrorJustReturn: ())
        
        let done = doneButton.rx.tap
            .map({[weak self] in
                return self?.addressTextField.text ?? ""
            })
            .asDriver(onErrorDriveWith: .empty())
        
        let viewDidAppear = rx
            .methodInvoked(#selector(viewDidAppear(_:)))
            .map{ _ in () }
            .asDriver(onErrorDriveWith: .empty())
        
        
        
        let output = viewModel.transform(
            input: NewServerViewModel.Input(
                noticeClick: noticeTap,
                done: done,
                viewDidAppear: viewDidAppear
            ))
        
        //键盘显示与隐藏
        output.showKeyboard.drive(onNext: { [weak self] show in
            if show {
                _ = self?.addressTextField.becomeFirstResponder()
            }
            else{
                self?.addressTextField.resignFirstResponder()
            }
        }).disposed(by: rx.disposeBag)
        
        //点击教程
        output.notice.drive(onNext: {[weak self] url in
            self?.navigationController?.present(BarkSFSafariViewController(url: url), animated: true, completion: nil)
        }).disposed(by: rx.disposeBag)
        
        //URL文本框文本
        output.urlText
            .drive(self.addressTextField.rx.text)
            .disposed(by: rx.disposeBag)
        
        //退出页面
        output.pop.drive(onNext: {[weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }).disposed(by: rx.disposeBag)
        
        //弹出提示文本
        output.showSnackbar.drive(onNext: {[weak self] text in
            self?.showSnackbar(text: text)
        }).disposed(by: rx.disposeBag)

    }

}
