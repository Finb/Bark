//
//  BaseTableViewCell.swift
//  Bark
//
//  Created by huangfeng on 2020/11/20.
//  Copyright © 2020 Fin. All rights reserved.
//

import UIKit

class BaseTableViewCell: UITableViewCell {
    var viewModel:ViewModel?
    func bindViewModel(model:ViewModel){
        self.viewModel = model
    }
}
