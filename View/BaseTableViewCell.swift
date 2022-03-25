//
//  BaseTableViewCell.swift
//  Bark
//
//  Created by huangfeng on 2020/11/20.
//  Copyright © 2020 Fin. All rights reserved.
//

import UIKit

class BaseTableViewCell<T>: UITableViewCell where T: ViewModel {
    var viewModel: T?
    func bindViewModel(model: T) {
        self.viewModel = model
    }
}
