//
//  CrashReportViewController.swift
//  Bark
//
//  Created by huangfeng on 2023/9/18.
//  Copyright © 2023 Fin. All rights reserved.
//

import UIKit

class CrashReportViewController: UIViewController {
    var crashLog = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        self.overrideUserInterfaceStyle = .light
        self.view.backgroundColor = UIColor.white

        let warningIcon = UIImageView(image: UIImage(named: "warning"))
        self.view.addSubview(warningIcon)

        let crashedTitle = UILabel()
        crashedTitle.text = NSLocalizedString("crashed")
        crashedTitle.font = UIFont.preferredFont(ofSize: 30, weight: .bold)
        crashedTitle.adjustsFontForContentSizeCategory = true
        crashedTitle.textColor = UIColor(r255: 239, g255: 77, b255: 77)
        self.view.addSubview(crashedTitle)

        let contentlabel = UITextView()
        contentlabel.backgroundColor = UIColor.clear
        contentlabel.isEditable = false
        contentlabel.dataDetectorTypes = [.link]
        contentlabel.isScrollEnabled = false
        contentlabel.textContainerInset = .zero
        contentlabel.textContainer.lineFragmentPadding = 0
        contentlabel.font = UIFont.preferredFont(ofSize: 14)
        contentlabel.adjustsFontForContentSizeCategory = true
        contentlabel.textColor = UIColor(r255: 51, g255: 51, b255: 51)
        contentlabel.text = NSLocalizedString("crashContent")
        self.view.addSubview(contentlabel)

        let copyButton = UIButton()
        copyButton.titleLabel?.font = UIFont.preferredFont(ofSize: 16, weight: .bold)
        copyButton.titleLabel?.adjustsFontForContentSizeCategory = true
        copyButton.setTitleColor(UIColor.white, for: .normal)
        copyButton.setTitle(NSLocalizedString("copyCrashLog"), for: .normal)
        copyButton.backgroundColor = UIColor(r255: 239, g255: 77, b255: 77)
        copyButton.clipsToBounds = true
        copyButton.layer.cornerRadius = 6
        self.view.addSubview(copyButton)

        warningIcon.snp.makeConstraints { make in
            make.top.equalTo(kSafeAreaInsets.top + 60)
            make.left.equalTo(15)
            make.width.height.equalTo(42)
        }
        crashedTitle.snp.makeConstraints { make in
            make.left.equalTo(warningIcon.snp.right).offset(10)
            make.centerY.equalTo(warningIcon)
        }
        contentlabel.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.top.equalTo(warningIcon.snp.bottom).offset(40)
        }
        copyButton.snp.makeConstraints { make in
            make.left.right.equalTo(contentlabel)
            make.top.equalTo(contentlabel.snp.bottom).offset(40)
            make.height.equalTo(44)
        }

        copyButton.rx.tap.subscribe { [weak self] _ in
            UIPasteboard.general.string = self?.crashLog
            ProgressHUD.inform(NSLocalizedString("Copy"))
        }.disposed(by: rx.disposeBag)
    }
}
