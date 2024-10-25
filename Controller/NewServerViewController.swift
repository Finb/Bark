//
//  NewServerViewController.swift
//  Bark
//
//  Created by huangfeng on 2018/6/25.
//  Copyright © 2018 Fin. All rights reserved.
//

import Material
import RxCocoa
import RxSwift
import SafariServices
import SnapKit
import UIKit

class NewServerViewController: BaseViewController<NewServerViewModel> {
    let scanButton: BKButton = {
        let button = BKButton()
        button.setImage(UIImage(named: "baseline_qr_code_scanner_black_24pt"), for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        button.hitTestSlop = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        button.tintColor = BKColor.grey.darken3
        return button
    }()
    
    lazy var addressTextField: TextField = {
        let textField = TextField()
        textField.keyboardType = .URL
        textField.placeholder = NSLocalizedString("ServerAddress")
        textField.detail = NSLocalizedString("ServerExample")
        textField.transition([.scale(0.85), .opacity(0)])
        textField.detailLabel.transition([.scale(0.85), .opacity(0)])
        textField.textColor = BKColor.grey.darken4
        textField.placeholderNormalColor = BKColor.grey.base
        textField.detailLabel.textColor = BKColor.grey.base
        
        textField.rightView?.grid.views = [scanButton]
        textField.rightViewMode = .whileEditing
        return textField
    }()
    
    let noticeLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("DeploymentDocuments")
        label.textColor = BKColor.blue.base
        label.font = UIFont.preferredFont(ofSize: 12)
        label.adjustsFontForContentSizeCategory = true
        label.transition([.scale(0.85), .opacity(0), .translate(x: 50)])
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer())
        return label
    }()
    
    lazy var doneButton: BKButton = {
        let doneButton = BKButton()
        doneButton.setImage(Icon.check, for: .normal)
        doneButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        navigationItem.setRightBarButtonItem(item: UIBarButtonItem(customView: doneButton))
        doneButton.tintColor = BKColor.grey.darken4
        return doneButton
    }()
    
    override func makeUI() {
        self.navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = NSLocalizedString("AddServer")
        
        self.view.layout(addressTextField)
            .top(kNavigationHeight + 40).left(10).right(10)
        
        self.view.addSubview(noticeLabel)
        noticeLabel.snp.makeConstraints { make in
            make.top.equalTo(self.addressTextField.snp.bottom).offset(40)
            make.left.equalTo(self.addressTextField)
        }
    }

    override func bindViewModel() {
        // 点击提醒按钮事件
        let noticeTap = noticeLabel.gestureRecognizers!.first!.rx
            .event
            .map { _ -> () in
                ()
            }
            .asDriver(onErrorJustReturn: ())
        
        // 点击完成按钮事件
        let done = doneButton.rx.tap
            .map { [weak self] in
                self?.addressTextField.text ?? ""
            }
            .asDriver(onErrorDriveWith: .empty())
        
        // 页面显示事件
        let viewDidAppear = rx
            .methodInvoked(#selector(viewDidAppear(_:)))
            .map { _ in () }
            .asDriver(onErrorDriveWith: .empty())
        
        // 扫描二维码事件
        let scannerDidScan = self.scanButton.rx.tap.flatMapLatest {[weak self] _ -> Observable<String> in
            let controller = QRScannerViewController()
            self?.navigationController?.present(controller, animated: true, completion: nil)
            return controller.scannerDidSuccess
        }.asDriver(onErrorDriveWith: .empty())
        
        let output = viewModel.transform(
            input: NewServerViewModel.Input(
                noticeClick: noticeTap,
                done: done,
                viewDidAppear: viewDidAppear,
                didScan: scannerDidScan
            ))
        
        // 键盘显示与隐藏
        output.showKeyboard.drive(onNext: { [weak self] show in
            if show {
                _ = self?.addressTextField.becomeFirstResponder()
            }
            else {
                self?.addressTextField.resignFirstResponder()
            }
        }).disposed(by: rx.disposeBag)
        
        // 点击教程
        output.notice.drive(onNext: { [weak self] url in
            self?.navigationController?.present(BarkSFSafariViewController(url: url), animated: true, completion: nil)
        }).disposed(by: rx.disposeBag)
        
        // URL文本框文本
        output.urlText
            .drive(self.addressTextField.rx.text)
            .disposed(by: rx.disposeBag)
        
        // 退出页面
        output.pop.drive(onNext: { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }).disposed(by: rx.disposeBag)
        
        // 弹出提示文本
        output.showSnackbar.drive(onNext: { [weak self] text in
            self?.showSnackbar(text: text)
        }).disposed(by: rx.disposeBag)
    }
}
