//
//  Defines.swift
//  Bark
//
//  Created by huangfeng on 2018/6/26.
//  Copyright © 2018 Fin. All rights reserved.
//

import RxCocoa
import UIKit

/// 将代码安全的运行在主线程
func dispatch_sync_safely_main_queue(_ block: () -> ()) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.sync {
            block()
        }
    }
}

extension UIViewController {
    func showSnackbar(text: String) {
        self.snackbarController?.snackbar.text = text
        self.snackbarController?.animate(snackbar: .visible)
        self.snackbarController?.animate(snackbar: .hidden, delay: 3)
    }
}

let kNavigationHeight: CGFloat = {
    kSafeAreaInsets.top + 44
}()

let kSafeAreaInsets: UIEdgeInsets = {
    UIWindow().safeAreaInsets
}()

func castOrThrow<T>(_ resultType: T.Type, _ object: Any) throws -> T {
    guard let returnValue = object as? T else {
        throw RxCocoaError.castingError(object: object, targetType: resultType)
    }

    return returnValue
}
