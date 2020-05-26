    //
//  Defines.swift
//  Bark
//
//  Created by huangfeng on 2018/6/26.
//  Copyright © 2018 Fin. All rights reserved.
//

import UIKit

/// 将代码安全的运行在主线程
func dispatch_sync_safely_main_queue(_ block: ()->()) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.sync {
            block()
        }
    }
}

extension UIViewController {
    func showSnackbar(text:String) {
        self.snackbarController?.snackbar.text = text
        self.snackbarController?.animate(snackbar: .visible)
        self.snackbarController?.animate(snackbar: .hidden, delay: 3)
    }
}

func NSLocalizedString( _ key:String ) -> String {
    return NSLocalizedString(key, comment: "")
}

let kNavigationHeight: CGFloat = {
    return kSafeAreaInsets.top + 44
}()

let kSafeAreaInsets:UIEdgeInsets = {
    if #available(iOS 12.0, *){
        return UIWindow().safeAreaInsets
    }
    else if #available(iOS 11.0, *){
        let inset = UIWindow().safeAreaInsets
        if inset.top > 0 { return inset}
        //iOS 11下，不是全面屏的手机 safeAreaInsets.top 是 0，与iOS12 不一致，这里强行让他们保持一致，方便开发
    }
    return UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
}()
