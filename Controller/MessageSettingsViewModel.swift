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
        var settings: Driver<[SectionModel<String, MessageSettingItem>]>
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

        let settings: [MessageSettingItem] = {
            var settings = [MessageSettingItem]()
            settings.append(.label(text: "iCloud"))
            settings.append(.iCloudStatus)
            settings.append(.label(text: NSLocalizedString("iCloudSync")))
            settings.append(.backup(viewModel: MutableTextCellViewModel(
                title: "\(NSLocalizedString("export"))/\(NSLocalizedString("import"))",
                text: Observable.merge([restoreSuccess, input.viewDidAppear])
                    .map { _ in
                        if let realm = try? Realm() {
                            return realm.objects(Message.self)
                                .filter("isDeleted != true")
                                .count
                        }
                        return 0
                    }
                    .map { count in
                        "\(count) \(NSLocalizedString("items"))"
                    }
                    .asDriver(onErrorDriveWith: .empty()))
            ))
            settings.append(.label(text: NSLocalizedString("exportOrImport")))
            settings.append(.archiveSetting(viewModel: ArchiveSettingCellViewModel(on: input.archiveSettingRelay)))
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

        // 导出数据
        let exportSuccess = input.backupAction
            .asObservable()
            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .compactMap { _ in
                if let realm = try? Realm() {
                    let messages = realm.objects(Message.self)
                        .filter("isDeleted != true")
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
            settings: Driver<[SectionModel<String, MessageSettingItem>]>
                .just([SectionModel(model: "model", items: settings)]),
            openUrl: openUrl,
            copyDeviceToken: copyDeviceToken,
            exportData: exportSuccess.asDriver(onErrorDriveWith: .empty()))
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
}
