//
//  BKButton.swift
//  Bark
//
//  Created by huangfeng on 2020/9/23.
//  Copyright © 2020 Fin. All rights reserved.
//

import UIKit

protocol AlignmentRectInsetsOverridable:class {
    var alignmentRectInsetsOverride: UIEdgeInsets? {get set}
}
protocol HitTestSlopable:class {
    var hitTestSlop: UIEdgeInsets {get set}
}

class BKButton: UIButton, HitTestSlopable,AlignmentRectInsetsOverridable  {
    
    var hitTestSlop:UIEdgeInsets = UIEdgeInsets.zero
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if hitTestSlop == UIEdgeInsets.zero {
            return super.point(inside: point, with:event)
        }
        else{
            return self.bounds.inset(by: hitTestSlop).contains(point)
        }
    }
    
    var alignmentRectInsetsOverride: UIEdgeInsets?
    override var alignmentRectInsets: UIEdgeInsets {
        return alignmentRectInsetsOverride ?? super.alignmentRectInsets
    }
}
