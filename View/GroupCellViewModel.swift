//
//  GroupCellViewModel.swift
//  Bark
//
//  Created by huangfeng on 2021/6/8.
//  Copyright © 2021 Fin. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class GroupCellViewModel:ViewModel {
    let name = BehaviorRelay<String?>(value: nil)
    let checked = BehaviorRelay<Bool>(value: false)

    init(groupFilterModel:GroupFilterModel) {
        self.name.accept(groupFilterModel.name)
        self.checked.accept(groupFilterModel.checked)
    }
}
