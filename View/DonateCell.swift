//
//  DonateCell.swift
//  Bark
//
//  Created by huangfeng on 11/13/24.
//  Copyright © 2024 Fin. All rights reserved.
//

import SwiftyStoreKit
import UIKit

class DonateCell: UITableViewCell {
    var title: String? = nil {
        didSet {
            self.textLabel?.text = title
        }
    }

    var productId: String? = nil {
        didSet {
            guard let productId else { return }
            if let cachePriceStr = Settings["bark.price.\(productId)"] {
                self.detailTextLabel?.text = cachePriceStr
                return
            }
            // 查询价格
            SwiftyStoreKit.retrieveProductsInfo([productId]) { result in
                if let product = result.retrievedProducts.first, let price = product.localizedPrice {
                    let priceStr = price + (product.localizedSubscriptionPeriod.isEmpty ? "" : " / \(product.localizedSubscriptionPeriod)")
                    Settings["bark.price.\(productId)"] = priceStr
                    self.detailTextLabel?.text = priceStr
                }
            }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.accessoryType = .disclosureIndicator
        self.backgroundColor = BKColor.background.secondary
        self.detailTextLabel?.textColor = BKColor.grey.darken2
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
