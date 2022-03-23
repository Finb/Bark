//
//  MessageSettingsViewModel.swift
//  Bark
//
//  Created by huangfeng on 2020/11/20.
//  Copyright © 2020 Fin. All rights reserved.
//

import Foundation
import Material
import RxCocoa
import RxDataSources
import RxSwift

class MessageSettingsViewModel: ViewModel, ViewModelType {
    struct Input {
        var itemSelected: Driver<MessageSettingItem>
        var deviceToken: Driver<String?>
    }

    struct Output {
        var settings: Driver<[SectionModel<String, MessageSettingItem>]>
        var openUrl: Driver<URL>
        var copyDeviceToken: Driver<String>
    }

    func transform(input: Input) -> Output {
        let settings: [MessageSettingItem] = {
            var settings = [MessageSettingItem]()
            settings.append(.label(text: "iCloud"))
            settings.append(.iCloudStatus)
            settings.append(.label(text: NSLocalizedString("iCloudSync")))
            settings.append(.archiveSetting(viewModel: ArchiveSettingCellViewModel(on: ArchiveSettingManager.shared.isArchive)))
            settings.append(.label(text: NSLocalizedString("archiveNote")))

            settings.append(.label(text: NSLocalizedString("info")))
            settings.append(.deviceToken(
                viewModel: MutableTextCellViewModel(
                    title: "Device Token",
                    text: input
                        .deviceToken
                        .map {
                            deviceToken in
                            if let deviceToken = deviceToken {
                                return "\(deviceToken.prefix(2))****\(deviceToken.suffix(4))"
                            }
                            return NSLocalizedString("unknown")
                        })
            ))
            settings.append(.label(text: NSLocalizedString("deviceTokenInfo")))

            if let infoDict = Bundle.main.infoDictionary,
               let runId = infoDict["GitHub Run Id"] as? String
            {
                settings.append(.detail(
                    title: "Github Run Id",
                    text: "\(runId)",
                    textColor: BKColor.grey.darken2,
                    url: URL(string: "https://github.com/Finb/Bark/actions/runs/\(runId)")))
                settings.append(.label(text: NSLocalizedString("buildDesc")))
            }

            settings.append(.label(text: NSLocalizedString("other")))
            settings.append(.detail(
                title: NSLocalizedString("faq"),
                text: nil,
                textColor: nil,
                url: URL(string: "https://day.app/2021/06/barkfaq/")))

            settings.append(.spacer(height: 0.5, color: BKColor.grey.lighten4))
            settings.append(.detail(
                title: NSLocalizedString("appSC"),
                text: nil,
                textColor: nil,
                url: URL(string: "https://github.com/Finb/Bark")))

            settings.append(.spacer(height: 0.5, color: BKColor.grey.lighten4))
            settings.append(.detail(
                title: NSLocalizedString("backendSC"),
                text: nil,
                textColor: nil,
                url: URL(string: "https://github.com/Finb/bark-server")))
            return settings
        }()

        settings.compactMap { item -> ArchiveSettingCellViewModel? in
            if case let MessageSettingItem.archiveSetting(viewModel) = item {
                return viewModel
            }
            return nil
        }
        .first?
        .on
        .subscribe(onNext: { on in
            ArchiveSettingManager.shared.isArchive = on
        }).disposed(by: rx.disposeBag)

        let openUrl = input.itemSelected.compactMap { item -> URL? in
            if case let MessageSettingItem.detail(_, _, _, url) = item {
                return url
            }
            return nil
        }

        let deviceTokenValue: BehaviorRelay<String?> = BehaviorRelay(value: nil)
        input.deviceToken.drive(deviceTokenValue)
            .disposed(by: rx.disposeBag)
        let copyDeviceToken = input.itemSelected.compactMap { item -> String? in
            if case MessageSettingItem.deviceToken = item {
                return deviceTokenValue.value
            }
            return nil
        }

        return Output(
            settings: Driver<[SectionModel<String, MessageSettingItem>]>
                .just([SectionModel(model: "model", items: settings)]),
            openUrl: openUrl,
            copyDeviceToken: copyDeviceToken)
    }
}

enum MessageSettingItem {
    // 普通标题标签
    case label(text: String)
    // iCloud 状态
    case iCloudStatus
    // 默认保存
    case archiveSetting(viewModel: ArchiveSettingCellViewModel)
    // 带 详细按钮的 文本cell
    case detail(title: String?, text: String?, textColor: UIColor?, url: URL?)
    // deviceToken
    case deviceToken(viewModel: MutableTextCellViewModel)
    // 分隔线
    case spacer(height: CGFloat, color: UIColor?)
}
