//
//  MessageSettingsViewModel.swift
//  Bark
//
//  Created by huangfeng on 2020/11/20.
//  Copyright © 2020 Fin. All rights reserved.
//

import Foundation
import Material
import RealmSwift
import RxCocoa
import RxDataSources
import RxSwift
import SwiftyJSON

class MessageSettingsViewModel: ViewModel, ViewModelType {
    struct Input {
        var itemSelected: Driver<MessageSettingItem>
        var deviceToken: Driver<String?>
        var backupAction: Driver<Void>
        var restoreAction: Driver<Data>
        var viewDidAppear: Observable<Void>
        var archiveSettingRelay: BehaviorRelay<Bool>
    }

    struct Output {
        var settings: Driver<[SectionModel<MessageSettingSection, MessageSettingItem>]>
        var openUrl: Driver<URL>
        var copyDeviceToken: Driver<String>
        var exportData: Driver<Data>
    }

    func transform(input: Input) -> Output {
        let restoreSuccess = input
            .restoreAction
            .compactMap { data -> Void? in
                guard let json = try? JSON(data: data), let arr = json.array else {
                    return nil
                }
                guard let realm = try? Realm() else {
                    return nil
                }
                try? realm.write {
                    for message in arr {
                        guard let id = message["id"].string else {
                            continue
                        }
                        guard let createDate = message["createDate"].int64 else {
                            continue
                        }

                        let title = message["title"].string
                        let body = message["body"].string
                        let url = message["url"].string
                        let group = message["group"].string

                        let messageObject = Message()
                        messageObject.id = id
                        messageObject.title = title
                        messageObject.body = body
                        messageObject.url = url
                        messageObject.group = group
                        messageObject.createDate = Date(timeIntervalSince1970: TimeInterval(createDate))
                        realm.add(messageObject, update: .modified)
                    }
                }
                return ()
            }.asObservable().share()

        let settings: [SectionModel<MessageSettingSection, MessageSettingItem>] = {
            var settings = [SectionModel<MessageSettingSection, MessageSettingItem>]()
            
            // 历史消息
            var messageSettings = [MessageSettingItem]()
            messageSettings.append(.backup(viewModel: MutableTextCellViewModel(
                title: "\(NSLocalizedString("export"))/\(NSLocalizedString("import"))",
                text: Observable.merge([restoreSuccess, input.viewDidAppear])
                    .map { _ in
                        if let realm = try? Realm() {
                            return realm.objects(Message.self)
                                .count
                        }
                        return 0
                    }
                    .map { count in
                        "\(count) \(NSLocalizedString("items"))"
                    }
                    .asDriver(onErrorDriveWith: .empty())
            )
            ))
            
            messageSettings.append(.archiveSetting(viewModel: ArchiveSettingCellViewModel(on: input.archiveSettingRelay)))
            
            settings.append(
                SectionModel(
                    model: MessageSettingSection(header: NSLocalizedString("historyMessage"), footer: NSLocalizedString("archiveNote")),
                    items: messageSettings
                )
            )
            
            // 信息
            var infosettings = [MessageSettingItem]()
            infosettings.append(.deviceToken(
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
                        }
                )
            ))

            if let infoDict = Bundle.main.infoDictionary,
               let runId = infoDict["GitHub Run Id"] as? String
            {
                infosettings.append(.detail(
                    title: "Github Run Id",
                    text: "\(runId)",
                    textColor: BKColor.grey.darken2,
                    url: URL(string: "https://github.com/Finb/Bark/actions/runs/\(runId)")
                ))
            }
            settings.append(
                SectionModel(
                    model: MessageSettingSection(header: NSLocalizedString("info"), footer: NSLocalizedString("buildDesc")),
                    items: infosettings
                )
            )
            
            // 其他
            var otherSettings = [MessageSettingItem]()
            otherSettings.append(.detail(
                title: NSLocalizedString("faq"),
                text: nil,
                textColor: nil,
                url: URL(string: NSLocalizedString("faqUrl"))
            ))

            otherSettings.append(.detail(
                title: NSLocalizedString("documentation"),
                text: nil,
                textColor: nil,
                url: URL(string: NSLocalizedString("docUrl"))
            ))
            otherSettings.append(.detail(
                title: NSLocalizedString("sourceCode"),
                text: nil,
                textColor: nil,
                url: URL(string: "https://github.com/Finb/Bark")
            ))
            
            settings.append(
                SectionModel(
                    model: MessageSettingSection(header: NSLocalizedString("other")),
                    items: otherSettings
                )
            )
            
            // 捐赠
            var donateSettings = [MessageSettingItem]()
            donateSettings.append(.donate(title: NSLocalizedString("oneTimeDonation"), productId: "bark.oneTimeDonation.18"))
            donateSettings.append(.donate(title: NSLocalizedString("continuousSupport"), productId: "bark.continuousSupport.18"))
            settings.append(
                SectionModel(
                    model: MessageSettingSection(
                        header: NSLocalizedString("donate"),
                        footer: nil
                    ),
                    items: donateSettings
                )
            )
            
            return settings
        }()

        let openUrl = input.itemSelected.compactMap { item -> URL? in
            if case MessageSettingItem.detail(_, _, _, let url) = item {
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

        // 导出数据
        let exportSuccess = input.backupAction
            .asObservable()
            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .compactMap { _ in
                if let realm = try? Realm() {
                    let messages = realm.objects(Message.self)
                        .sorted(byKeyPath: "createDate", ascending: false)

                    var arr = [[String: AnyObject]]()
                    for message in messages {
                        arr.append(message.toDictionary())
                    }
                    return try? JSON(arr).rawData(options: JSONSerialization.WritingOptions.prettyPrinted)
                }
                return nil
            }

        return Output(
            settings: Driver<[SectionModel<MessageSettingSection, MessageSettingItem>]>
                .just(settings),
            openUrl: openUrl,
            copyDeviceToken: copyDeviceToken,
            exportData: exportSuccess.asDriver(onErrorDriveWith: .empty())
        )
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
    // 备份还原按钮
    case backup(viewModel: MutableTextCellViewModel)
    // deviceToken
    case deviceToken(viewModel: MutableTextCellViewModel)
    // 分隔线
    case spacer(height: CGFloat, color: UIColor?)
    // 捐赠
    case donate(title: String, productId: String)
}

struct MessageSettingSection {
    var header: String?
    var footer: String?
}
