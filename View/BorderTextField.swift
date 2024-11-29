//
//  BorderTextField.swift
//  Bark
//
//  Created by huangfeng on 2023/2/6.
//  Copyright © 2023 Fin. All rights reserved.
//

import UIKit

class InsetTextField: UITextField {
    var insets = UIEdgeInsets.zero

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let bounds = super.textRect(forBounds: bounds)
        return bounds.inset(by: insets)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        let bounds = super.textRect(forBounds: bounds)
        return bounds.inset(by: insets)
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        let bounds = super.textRect(forBounds: bounds)
        return bounds.inset(by: insets)
    }
}

class BorderTextField: InsetTextField {
    var isSelecting: Bool = true {
        didSet {
            UIView.animate(withDuration: 0.3) {
                if self.isSelecting {
                    self.backgroundView.borderColor = BKColor.blue.darken5
                    self.backgroundView.shadowColor = BKColor.blue.darken5
                    self.backgroundView.layer.shadowOpacity = 0.3
                }
                else {
                    self.backgroundView.borderColor = BKColor.grey.lighten2
                    self.backgroundView.shadowColor = BKColor.grey.lighten2
                    self.backgroundView.layer.shadowOpacity = 0
                }
            }
        }
    }
    
    let backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = BKColor.white
        view.isUserInteractionEnabled = false
        view.cornerRadiusPreset = .cornerRadius3
        view.shadowColor = BKColor.grey.lighten2
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
        view.layer.shadowRadius = 2
        view.layer.shadowOpacity = 0
        view.borderColor = BKColor.grey.lighten2
        view.borderWidthPreset = .border2
        
        return view
    }()
    
    init(title: String? = nil) {
        super.init(frame: CGRect.zero)
        self.insets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        self.textColor = BKColor.grey.darken3
        self.font = UIFont.preferredFont(ofSize: 14)
        self.adjustsFontForContentSizeCategory = true
        self.textAlignment = .left
        
        self.insertSubview(backgroundView, at: 0)
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        self.delegate = self
    }
    override var placeholder: String? {
        didSet{
            self.attributedPlaceholder = NSAttributedString(string: placeholder ?? "" , attributes: [
                .font: self.font ?? UIFont.preferredFont(ofSize: 14),
                .foregroundColor: BKColor.grey.darken1
            ])
        }
    }
    

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension BorderTextField: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.isSelecting = true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.isSelecting = false
    }
}
