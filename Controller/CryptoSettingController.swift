//
//  CryptoSettingController.swift
//  Bark
//
//  Created by huangfeng on 2022/11/10.
//  Copyright © 2022 Fin. All rights reserved.
//

import RxSwift
import UIKit

class CryptoSettingController: BaseViewController<CryptoSettingViewModel> {
    let algorithmFeild = DropBoxView(values: ["AES128", "AES192", "AES256"])
    let modeFeild = DropBoxView(values: ["CBC", "ECB", "GCM"])
    let paddingField = DropBoxView(values: ["pkcs7"])

    let keyTextField: BorderTextField = {
        let textField = BorderTextField(title: "Key")
        textField.font = UIFont.preferredFont(ofSize: 14)
        textField.adjustsFontForContentSizeCategory = true
        textField.placeholder = String(format: NSLocalizedString("enterKey"), 16)
        return textField
    }()

    let ivTextField: BorderTextField = {
        let textField = BorderTextField(title: "IV")
        textField.font = UIFont.preferredFont(ofSize: 14)
        textField.adjustsFontForContentSizeCategory = true
        return textField
    }()

    let doneButton: BKButton = {
        let btn = BKButton()
        btn.setTitle(NSLocalizedString("done"), for: .normal)
        btn.setTitleColor(BKColor.lightBlue.darken3, for: .normal)
        btn.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        btn.fontSize = 14
        return btn
    }()

    let copyButton: UIButton = {
        let btn = GradientButton()
        btn.setTitle(NSLocalizedString("copyExample"), for: .normal)
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.titleLabel?.font = UIFont.preferredFont(ofSize: 14, weight: .medium)
        btn.titleLabel?.adjustsFontForContentSizeCategory = true
        btn.layer.cornerRadius = 8
        btn.clipsToBounds = true
        btn.applyGradient(
            withColours: [
                UIColor(r255: 36, g255: 51, b255: 236),
                UIColor(r255: 70, g255: 44, b255: 233)
            ],
            gradientOrientation: .horizontal
        )
        return btn
    }()

    let scrollView = UIScrollView()
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func makeUI() {
        self.title = NSLocalizedString("encryptionSettings")
        self.navigationItem.setRightBarButtonItem(item: UIBarButtonItem(customView: doneButton))

        self.view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        func getTitleLabel(title: String) -> UILabel {
            let label = UILabel()
            label.font = UIFont.preferredFont(ofSize: 14)
            label.adjustsFontForContentSizeCategory = true
            label.textColor = BKColor.grey.darken4
            label.text = title
            return label
        }

        let algorithmLabel = getTitleLabel(title: NSLocalizedString("algorithm"))
        let modeLabel = getTitleLabel(title: NSLocalizedString("mode"))
        let paddingLabel = getTitleLabel(title: "Padding")
        let keyLabel = getTitleLabel(title: "Key")
        let ivLabel = getTitleLabel(title: "Iv")

        self.scrollView.addSubview(algorithmLabel)
        self.scrollView.addSubview(algorithmFeild)

        self.scrollView.addSubview(modeLabel)
        self.scrollView.addSubview(modeFeild)

        self.scrollView.addSubview(paddingLabel)
        self.scrollView.addSubview(paddingField)

        self.scrollView.addSubview(keyLabel)
        self.scrollView.addSubview(keyTextField)

        self.scrollView.addSubview(ivLabel)
        self.scrollView.addSubview(ivTextField)

        self.scrollView.addSubview(copyButton)

        self.view.backgroundColor = UIColor.white

        algorithmLabel.snp.makeConstraints { make in
            make.top.equalTo(24)
            make.left.equalTo(24)
        }
        algorithmFeild.snp.makeConstraints { make in
            make.top.equalTo(algorithmLabel.snp.bottom).offset(5)
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.height.equalTo(45)
            make.width.equalToSuperview().offset(-40)
        }

        modeLabel.snp.makeConstraints { make in
            make.top.equalTo(algorithmFeild.snp.bottom).offset(20)
            make.left.equalTo(algorithmLabel)
        }
        modeFeild.snp.makeConstraints { make in
            make.left.right.height.equalTo(algorithmFeild)
            make.top.equalTo(modeLabel.snp.bottom).offset(5)
        }

        paddingLabel.snp.makeConstraints { make in
            make.top.equalTo(modeFeild.snp.bottom).offset(20)
            make.left.equalTo(algorithmLabel)
        }
        paddingField.snp.makeConstraints { make in
            make.left.right.height.equalTo(modeFeild)
            make.top.equalTo(paddingLabel.snp.bottom).offset(5)
        }

        keyLabel.snp.makeConstraints { make in
            make.top.equalTo(paddingField.snp.bottom).offset(20)
            make.left.equalTo(algorithmLabel)
        }
        keyTextField.snp.makeConstraints { make in
            make.left.right.height.equalTo(paddingField)
            make.top.equalTo(keyLabel.snp.bottom).offset(5)
        }

        ivLabel.snp.makeConstraints { make in
            make.top.equalTo(keyTextField.snp.bottom).offset(20)
            make.left.equalTo(algorithmLabel)
        }
        ivTextField.snp.makeConstraints { make in
            make.left.right.height.equalTo(keyTextField)
            make.top.equalTo(ivLabel.snp.bottom).offset(5)
        }

        copyButton.snp.makeConstraints { make in
            make.left.equalTo(ivTextField)
            make.right.equalTo(ivTextField)
            make.height.equalTo(42)
            make.top.equalTo(ivTextField.snp.bottom).offset(25)
            make.bottom.equalToSuperview().offset(-20)
        }

        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(resign)))
    }

    @objc func resign() {
        self.view.endEditing(true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = BKColor.white
    }

    override func bindViewModel() {
        func getFieldValues() -> CryptoSettingFields {
            return CryptoSettingFields(
                algorithm: self.algorithmFeild.currentValue!,
                mode: self.modeFeild.currentValue!,
                padding: self.paddingField.currentValue!,
                key: self.keyTextField.text,
                iv: self.ivTextField.text
            )
        }

        let output = viewModel.transform(input: CryptoSettingViewModel.Input(
            algorithmChanged: self.algorithmFeild
                .rx
                .currentValueChanged
                .compactMap { $0 }
                .asDriver(onErrorDriveWith: .empty()),

            copyScript: copyButton
                .rx
                .tap
                .map { getFieldValues() }
                .asDriver(onErrorDriveWith: .empty()),

            done: doneButton
                .rx
                .tap
                .map { getFieldValues() }
                .asDriver(onErrorDriveWith: .empty())
        ))

        output.initial.drive(onNext: { [weak self] val in
            self?.algorithmFeild.values = val.algorithmList.map { $0.rawValue }
            self?.modeFeild.values = val.modeList
            self?.paddingField.values = val.paddingList
            if let fields = val.initialFields {
                self?.algorithmFeild.currentValue = fields.algorithm
                self?.modeFeild.currentValue = fields.mode
                self?.paddingField.currentValue = fields.padding
                self?.keyTextField.text = fields.key
                self?.ivTextField.text = fields.iv
            }
            self?.setIvLengthPlaceholder(mode: self?.modeFeild.currentValue)
        }).disposed(by: rx.disposeBag)

        output.modeListChanged
            .drive(self.modeFeild.rx.values)
            .disposed(by: rx.disposeBag)

        output.paddingListChanged
            .drive(self.paddingField.rx.values)
            .disposed(by: rx.disposeBag)

        output.keyLengthChanged.drive(onNext: { [weak self] keyLength in
            self?.keyTextField.placeholder = String(format: NSLocalizedString("enterKey"), keyLength)
        }).disposed(by: rx.disposeBag)
        
        self.modeFeild
            .rx
            .currentValueChanged
            .subscribe(onNext: { [weak self] val in
                self?.setIvLengthPlaceholder(mode: val)
            }).disposed(by: rx.disposeBag)

        output.showSnackbar.drive(onNext: { text in
            HUDError(text)
        }).disposed(by: rx.disposeBag)

        output.done.drive(onNext: { [weak self] in
            self?.navigationController?.dismiss(animated: true)
        }).disposed(by: rx.disposeBag)

        output.copy.drive(onNext: { text in
            UIPasteboard.general.string = text
            HUDSuccess(NSLocalizedString("Copy"))
        }).disposed(by: rx.disposeBag)
    }
    
    private func setIvLengthPlaceholder(mode: String?) {
        guard let mode else {
            return
        }
        if let length = ["CBC": 16, "GCM": 12][mode] {
            self.ivTextField.placeholder = String(format: NSLocalizedString("enterIv"), length)
        } else {
            self.ivTextField.placeholder = ""
        }
    }
}
