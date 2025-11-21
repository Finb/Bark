//
//  UIFont+Extension.swift
//  Bark
//
//  Created by huangfeng on 10/25/24.
//  Copyright © 2024 Fin. All rights reserved.
//

import UIKit

extension UIFont {
    class func preferredFont(ofSize size: CGFloat, weight: Weight = .regular) -> UIFont {
        return UIFontMetrics.default.scaledFont(for: UIFont.systemFont(ofSize: size, weight: weight))
    }
}

extension UIFont {
    func bold() -> UIFont {
        if let descriptor = self.fontDescriptor.withSymbolicTraits(.traitBold) {
            return UIFont(descriptor: descriptor, size: self.pointSize)
        }
        return self
    }
    
    func italic() -> UIFont {
        if let descriptor = self.fontDescriptor.withSymbolicTraits(.traitItalic) {
            return UIFont(descriptor: descriptor, size: self.pointSize)
        }
        return self
    }
}
