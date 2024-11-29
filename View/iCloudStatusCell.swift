//
//  iCloudStatusCell.swift
//  Bark
//
//  Created by huangfeng on 2020/5/29.
//  Copyright © 2020 Fin. All rights reserved.
//

import CloudKit
import UIKit

class iCloudStatusCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = BKColor.background.secondary
        self.textLabel?.text = NSLocalizedString("iCloudSatatus")
        self.detailTextLabel?.text = ""
        self.detailTextLabel?.textColor = BKColor.grey.darken2
        CKContainer.default().accountStatus { status, _ in
            dispatch_sync_safely_main_queue {
                switch status {
                case .available:
                    self.detailTextLabel?.text = NSLocalizedString("available")
                case .noAccount, .restricted, .temporarilyUnavailable:
                    self.detailTextLabel?.text = NSLocalizedString("restricted")
                case .couldNotDetermine:
                    self.detailTextLabel?.text = NSLocalizedString("unknown")
                @unknown default:
                    break
                }
            }
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
