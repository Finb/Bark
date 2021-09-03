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
import Material

class MessageSettingsViewModel: ViewModel, ViewModelType {
    struct Input {
        var itemSelected: Driver<MessageSettingItem>
    }
    struct Output {
        var settings:Driver<[SectionModel<String, MessageSettingItem>]>
        var openUrl:Driver<URL>
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
            settings.append(.notificationSetting(viewModel: NotificationSettingCellViewModel(on: NotificationDismissSettingManager.shared.willDismiss)))
            settings.append(.label(text: NSLocalizedString("notificationNote")))
            
            
            if let infoDict = Bundle.main.infoDictionary,
               let runId = infoDict["GitHub Run Id"] as? String{
                settings.append(.label(text: NSLocalizedString("buildInfo")))
                settings.append(.detail(
                                    title: "Github Run Id",
                                    text:"\(runId)",
                                    textColor: Color.grey.darken2,
                                    url: URL(string: "https://github.com/Finb/Bark/actions/runs/\(runId)")))
                settings.append(.label(text: NSLocalizedString("buildDesc")))
            }
            
            
            settings.append(.label(text: NSLocalizedString("other")))
            settings.append(.detail(
                                title: NSLocalizedString("faq"),
                                text: nil,
                                textColor: nil,
                                url: URL(string: "https://day.app/2021/06/barkfaq/")))
            
            settings.append(.spacer(height: 0.5, color: Color.grey.lighten4))
            settings.append(.detail(
                                title: NSLocalizedString("appSC"),
                                text: nil,
                                textColor: nil,
                                url: URL(string: "https://github.com/Finb/Bark")))
            
            settings.append(.spacer(height: 0.5, color: Color.grey.lighten4))
            settings.append(.detail(
                                title: NSLocalizedString("backendSC"),
                                text: nil,
                                textColor: nil,
                                url: URL(string: "https://github.com/Finb/bark-server")))
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
        
        settings.compactMap { (item) -> NotificationSettingCellViewModel? in
            if case let MessageSettingItem.notificationSetting(viewModel) = item {
                return viewModel
            }
            return nil
        }
        .first?
        .on
        .subscribe(onNext: { (on) in
            NotificationDismissSettingManager.shared.isArchive = on
        }).disposed(by: rx.disposeBag)
        
        let openUrl = input.itemSelected.compactMap { item -> URL? in
            if case let MessageSettingItem.detail(_, _, _, url) = item {
                return url
            }
            return nil
        }
        
        
        return Output(
            settings: Driver<[SectionModel<String, MessageSettingItem>]>
                        .just([SectionModel(model: "model", items: settings)]),
            openUrl: openUrl
        )
    }
    
}

enum MessageSettingItem {
    // 普通标题标签
    case label(text:String)
    // iCloud 状态
    case iCloudStatus
    // 默认保存
    case archiveSetting(viewModel:ArchiveSettingCellViewModel)
    // 默认不收回
    case notificationSetting(viewModel:NotificationSettingCellViewModel)
    // 带 详细按钮的 文本cell
    case detail(title:String?, text:String?, textColor:UIColor?, url:URL?)
    // 分隔线
    case spacer(height:CGFloat, color:UIColor?)
}
