//
//  ArchiveSettingCellViewModel.swift
//  Bark
//
//  Created by huangfeng on 2020/11/20.
//  Copyright © 2020 Fin. All rights reserved.
//

import Foundation
import RxCocoa
class ArchiveSettingCellViewModel: ViewModel {
    var on: BehaviorRelay<Bool>
    init(on:Bool) {
        self.on = BehaviorRelay<Bool>(value: on)
        super.init()
    }
}
