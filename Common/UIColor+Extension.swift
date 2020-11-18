//
//  UIColor+Extension.swift
//  Bark
//
//  Created by huangfeng on 2018/6/25.
//  Copyright © 2018 Fin. All rights reserved.
//

import UIKit

extension UIColor {
    convenience public init(r255:CGFloat, g255:CGFloat, b255:CGFloat, a255:CGFloat = 255) {
        self.init(red: r255/255, green: g255/255, blue: b255/255, alpha: a255/255)
    }
    class func image(color:UIColor, size:CGSize = CGSize(width: 1, height: 1)) -> UIImage{
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(CGRect(origin: CGPoint.zero, size: size))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image! //context应该不会没get到吧~ 所以直接强解了
    }
    
    var image: UIImage {
        return UIColor.image(color: self)
    }
}
