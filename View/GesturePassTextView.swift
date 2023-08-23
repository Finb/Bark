//
//  GesturePassTextView.swift
//  Bark
//
//  Created by huangfeng on 2023/7/26.
//  Copyright © 2023 Fin. All rights reserved.
//

import UIKit

class GesturePassTextView: UITextView {
    var superCell: UITableViewCell? = nil
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let cell = superCell {
            cell.touchesBegan(touches, with: event)
            return
        }
        super.touchesBegan(touches, with: event)
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let cell = superCell {
            cell.touchesMoved(touches, with: event)
            return
        }
        super.touchesMoved(touches, with: event)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let cell = superCell {
            cell.touchesEnded(touches, with: event)
            return
        }
        super.touchesEnded(touches, with: event)
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let cell = superCell {
            cell.touchesCancelled(touches, with: event)
            return
        }
        super.touchesCancelled(touches, with: event)
    }
}
