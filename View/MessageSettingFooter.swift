//
//  MessageSettingFooter.swift
//  Bark
//
//  Created by huangfeng on 11/14/24.
//  Copyright © 2024 Fin. All rights reserved.
//

import UIKit

class MessageSettingFooter: UITextView, UITextViewDelegate {
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 80), textContainer: .none)
        self.backgroundColor = UIColor.clear
        self.isEditable = false
        self.delegate = self
        
        // 版本号
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        // build号
        let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        
        let attr = NSMutableAttributedString(string: "\(NSLocalizedString("version")) \(appVersion) (\(buildVersion))\n", attributes: [.font: UIFont.preferredFont(ofSize: 12), .foregroundColor: BKColor.grey.darken1])
        attr.append(NSAttributedString(string: NSLocalizedString("privacyPolicy"), attributes: [.link: "privacyPolicy"]))
        attr.append(NSAttributedString(string: "  ·  "))
        attr.append(NSAttributedString(string: NSLocalizedString("userAgreement"), attributes: [.link: "userAgreement"]))
        attr.append(NSAttributedString(string: "  ·  "))
        attr.append(NSAttributedString(string: NSLocalizedString("restoreSubscription"), attributes: [.link: "restoreSubscription"]))
        
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 6
        attr.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: attr.length))
        
        self.attributedText = attr
        self.linkTextAttributes = [.foregroundColor: BKColor.grey.darken1, .underlineStyle: NSUnderlineStyle.single.rawValue, .font: UIFont.preferredFont(ofSize: 12)]
        self.textAlignment = .center
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var openLinkHandler: ((String) -> Void)?
    func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange) -> Bool {
        self.openLinkHandler?(url.absoluteString)
        return false
    }
}
