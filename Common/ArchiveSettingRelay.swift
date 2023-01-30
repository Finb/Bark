//
//  ArchiveSettingRelay.swift
//  Bark
//
//  Created by huangfeng on 2023/1/30.
//  Copyright © 2023 Fin. All rights reserved.
//

import RxCocoa
import UIKit
class ArchiveSettingRelay: NSObject {
    static let shared = ArchiveSettingRelay()
    let isArchiveRelay: BehaviorRelay<Bool>

    override private init() {
        self.isArchiveRelay = BehaviorRelay<Bool>(value: ArchiveSettingManager.shared.isArchive)
        super.init()

        self.isArchiveRelay.subscribe { val in
            ArchiveSettingManager.shared.isArchive = val
        }.disposed(by: rx.disposeBag)
    }
}
