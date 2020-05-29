//
//  iCloudStatusCell.swift
//  Bark
//
//  Created by huangfeng on 2020/5/29.
//  Copyright © 2020 Fin. All rights reserved.
//

import UIKit
import CloudKit

class iCloudStatusCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        
        self.textLabel?.text = NSLocalizedString("iCloudSatatus")
        self.detailTextLabel?.text = ""
        CKContainer.default().accountStatus { (status, error) in
            dispatch_sync_safely_main_queue {
                switch status {
                case .available:
                    self.detailTextLabel?.text = NSLocalizedString("available")
                    
                case .noAccount, .restricted:
                    self.detailTextLabel?.text = NSLocalizedString("restricted")
                case .couldNotDetermine:
                    self.detailTextLabel?.text = NSLocalizedString("unknown")
                @unknown default:
                    break
                }
            }
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
