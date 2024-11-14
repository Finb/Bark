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
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 40), textContainer: .none)
        self.backgroundColor = UIColor.clear
        self.isEditable = false
        self.delegate = self
        
        self.font = UIFont.preferredFont(ofSize: 12)
        self.textColor = BKColor.grey.darken1
        
        let attr = NSMutableAttributedString(string: NSLocalizedString("privacyPolicy"), attributes: [.link: "privacyPolicy"])
        attr.append(NSAttributedString(string: "  ·  "))
        attr.append(NSAttributedString(string: NSLocalizedString("userAgreement"), attributes: [.link: "userAgreement"]))
        attr.append(NSAttributedString(string: "  ·  "))
        attr.append(NSAttributedString(string: NSLocalizedString("restoreSubscription"), attributes: [.link: "restoreSubscription"]))
        
        self.attributedText = attr
        self.linkTextAttributes = [.foregroundColor: BKColor.grey.darken1, .underlineStyle: NSUnderlineStyle.single.rawValue]
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
