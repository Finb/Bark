//
//  SoundsViewModel.swift
//  Bark
//
//  Created by huangfeng on 2020/11/17.
//  Copyright © 2020 Fin. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import AVKit
import RxDataSources

class SoundsViewModel:ViewModel,ViewModelType {
    
    struct Input {
        var soundSelected:Driver<SoundCellViewModel>
    }
    struct Output {
        var audios:Observable<[ SectionModel<String, SoundCellViewModel>]>
        var copyNameAction: Driver<String>
        var playAction: Driver<CFURL>
    }
    
    func transform(input: Input) -> Output {
        let models = { () -> [AVURLAsset] in
            var urls = Bundle.main.urls(forResourcesWithExtension: "caf", subdirectory: nil) ?? []
            urls.sort { (u1, u2) -> Bool in
                u1.lastPathComponent.localizedStandardCompare(u2.lastPathComponent) == ComparisonResult.orderedAscending
            }
            let audios = urls.map { (url) -> AVURLAsset in
                let asset = AVURLAsset(url: url)
                return asset
            }
            return audios
        }().map { SoundCellViewModel(model: $0 ) }
       
        let copyAction = Driver.merge(
            models.map { $0.copyNameAction.asDriver(onErrorDriveWith: .empty()) }
        ).asDriver()
        
        return Output(
            audios: Observable.just([SectionModel(model: "model", items: models)]),
            copyNameAction: copyAction,
            playAction: input.soundSelected.map{ $0.model.url as CFURL }
        )
    }
    
}
