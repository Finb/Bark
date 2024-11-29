//
//  BarkSFSafariViewController.swift
//  Bark
//
//  Created by huangfeng on 2018/6/26.
//  Copyright © 2018 Fin. All rights reserved.
//

import SafariServices
import UIKit

class BarkSFSafariViewController: SFSafariViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    deinit {
        if #available(iOS 16.0, *) {
            Task {
                await SFSafariViewController.DataStore.default.clearWebsiteData()
            }
        }
    }
}
