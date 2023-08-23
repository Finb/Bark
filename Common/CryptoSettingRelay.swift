//
//  CryptoSettingRelay.swift
//  Bark
//
//  Created by huangfeng on 2023/3/7.
//  Copyright © 2023 Fin. All rights reserved.
//

import Foundation
import RxCocoa

class CryptoSettingRelay: NSObject {
    static let shared = CryptoSettingRelay()
    let fields: BehaviorRelay<CryptoSettingFields?>

    override private init() {
        self.fields = BehaviorRelay<CryptoSettingFields?>(value: CryptoSettingManager.shared.fields)
        super.init()

        self.fields.subscribe { val in
            CryptoSettingManager.shared.fields = val
        }.disposed(by: rx.disposeBag)
    }
}
