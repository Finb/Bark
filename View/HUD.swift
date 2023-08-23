//
//  HUD.swift
//  Bark
//
//  Created by huangfeng on 2023/3/6.
//  Copyright © 2023 Fin. All rights reserved.
//

import SVProgressHUD
import UIKit
class BarkProgressHUD: SVProgressHUD {
    override class func displayDuration(for string: String?) -> TimeInterval {
        return min(Double((string ?? "").utf8.count) * 0.06 + 0.5, 5.0)
    }
}

open class ProgressHUD: NSObject {
    open class func show() {
        BarkProgressHUD.show()
    }

    open class func showWithClearMask() {
        BarkProgressHUD.show()
    }

    open class func dismiss() {
        BarkProgressHUD.dismiss()
    }

    open class func showWithStatus(_ status: String!) {
        BarkProgressHUD.show(withStatus: status)
    }

    open class func success(_ status: String!) {
        BarkProgressHUD.showSuccess(withStatus: status)
    }

    open class func error(_ status: String!) {
        BarkProgressHUD.showError(withStatus: status)
    }

    open class func inform(_ status: String!) {
        BarkProgressHUD.showInfo(withStatus: status)
    }
}

public func HUDSuccess(_ status: String?) {
    ProgressHUD.success(status ?? "")
}

public func HUDError(_ status: String?) {
    ProgressHUD.error(status ?? "")
}

public func HUDInform(_ status: String?) {
    ProgressHUD.inform(status ?? "")
}

public func HUDShow() {
    ProgressHUD.show()
}

public func HUDShowWithStatus(_ status: String!) {
    ProgressHUD.showWithStatus(status)
}

public func HUDDismiss() {
    ProgressHUD.dismiss()
}
