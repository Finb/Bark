//
//  SoundCellViewModel.swift
//  Bark
//
//  Created by huangfeng on 2020/11/17.
//  Copyright © 2020 Fin. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import AVKit

class SoundCellViewModel:ViewModel {
    let name = BehaviorRelay<String>(value: "")
    let duration = BehaviorRelay<CMTime>(value: .zero)
    
    let copyNameAction = PublishRelay<String>()
    let playAction = PublishRelay<CFURL>()
    
    let model: AVURLAsset
    init(model: AVURLAsset) {
        self.model = model
        name.accept(model.url.deletingPathExtension().lastPathComponent)
        duration.accept(model.duration)
    }
}
