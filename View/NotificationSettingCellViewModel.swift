//
//  NotificationSettingCellViewModel.swift
//  Bark
//
//  Created by Jiawei Duan on 9/3/21.
//  Copyright © 2021 Fin. All rights reserved.
//

import Foundation
import RxCocoa
class NotificationSettingCellViewModel: ViewModel {
    var on: BehaviorRelay<Bool>
    init(on:Bool) {
        self.on = BehaviorRelay<Bool>(value: on)
        super.init()
    }
}
