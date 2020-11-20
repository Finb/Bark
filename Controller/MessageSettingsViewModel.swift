//
//  MessageSettingsViewModel.swift
//  Bark
//
//  Created by huangfeng on 2020/11/20.
//  Copyright © 2020 Fin. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RxDataSources

class MessageSettingsViewModel: ViewModel, ViewModelType {
    struct Input {
        
    }
    struct Output {
        var settings:Driver<[SectionModel<String, MessageSettingItem>]>
    }
    func transform(input: Input) -> Output {
        
        let settings:[MessageSettingItem] = {
            var settings = [MessageSettingItem]()
            settings.append(.label(text: "iCloud"))
            settings.append(.iCloudStatus)
            settings.append(.label(text: NSLocalizedString("iCloudSync")))
            settings.append(.label(text: NSLocalizedString("defaultArchiveSettings")))
            settings.append(.archiveSetting(viewModel: ArchiveSettingCellViewModel(on: ArchiveSettingManager.shared.isArchive)))
            settings.append(.label(text: NSLocalizedString("archiveNote")))
            return settings
        }()
        
        settings.compactMap { (item) -> ArchiveSettingCellViewModel? in
            if case let MessageSettingItem.archiveSetting(viewModel) = item {
                return viewModel
            }
            return nil
        }
        .first?
        .on
        .subscribe(onNext: { (on) in
            ArchiveSettingManager.shared.isArchive = on
        }).disposed(by: rx.disposeBag)

        return Output(settings: Driver<[SectionModel<String, MessageSettingItem>]>
                        .just([SectionModel(model: "model", items: settings)]))
    }
    
}

enum MessageSettingItem {
    case label(text:String)
    case iCloudStatus
    case archiveSetting(viewModel:ArchiveSettingCellViewModel)
}
