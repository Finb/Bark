//
//  BKLabel.swift
//  Bark
//
//  Created by huangfeng on 2020/5/29.
//  Copyright © 2020 Fin. All rights reserved.
//

import UIKit

class BKLabel: UILabel {

    var hitTestSlop:UIEdgeInsets = UIEdgeInsets.zero
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if hitTestSlop == UIEdgeInsets.zero {
            return super.point(inside: point, with:event)
        }
        else{
            return self.bounds.inset(by: hitTestSlop).contains(point)
        }
    }

}
