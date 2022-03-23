//
//  DeviceTokenCellViewModel.swift
//  Bark
//
//  Created by huangfeng on 2022/3/23.
//  Copyright © 2022 Fin. All rights reserved.
//

import RxCocoa
import UIKit
class MutableTextCellViewModel: ViewModel {
    var title: String
    var text: Driver<String>
    init(title: String, text: Driver<String>) {
        self.title = title
        self.text = text
        super.init()
    }
}
