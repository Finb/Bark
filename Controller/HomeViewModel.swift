//
//  HomeViewModel.swift
//  Bark
//
//  Created by huangfeng on 2020/11/18.
//  Copyright © 2020 Fin. All rights reserved.
//

import Foundation
import RxCocoa
import RxDataSources
import RxSwift
import SwiftyJSON
import UserNotifications

class HomeViewModel: ViewModel, ViewModelType {
    struct Input {
        let addCustomServerTap: Driver<Void>
        let serverListTap: Driver<Void>
        let viewDidAppear: Driver<Void>
        let start: Driver<Void>
        let clientState: Driver<Client.ClienState>
        let authorizationStatus: Single<UNAuthorizationStatus>
        let startRequestAuthorizationCreator: () -> Observable<Bool>
    }

    struct Output {
        let previews: Driver<[SectionModel<String, PreviewCardCellViewModel>]>
        let push: Driver<ViewModel>
        let present: Driver<ViewModel>
        let title: Driver<String>
        let clienStateChanged: Driver<Client.ClienState>
        let tableViewHidden: Driver<Bool>
        let showSnackbar: Driver<String>
        let alertServerError: Driver<String>
        let startButtonEnable: Driver<Bool>
        let copy: Driver<String>
        let preview: Driver<URL>
        let reloadData: Driver<Void>
        let registerForRemoteNotifications: Driver<Void>
    }
    
    let previews: [PreviewModel] = [
        PreviewModel(
            body: "CustomedNotificationContent".localized,
            notice: "Notice1".localized
        ),
        PreviewModel(
            title: "CustomedNotificationTitle".localized,
            body: "CustomedNotificationContent".localized,
            notice: "Notice2".localized
        ),
        PreviewModel(
            body: "notificationSound".localized,
            notice: "setSounds".localized,
            queryParameter: "sound=minuet",
            moreInfo: "viewAllSounds".localized,
            moreViewModel: SoundsViewModel()
        ),
        PreviewModel(
            body: "ringtone".localized,
            notice: "ringtoneNotice".localized,
            queryParameter: "call=1"
        ),
        PreviewModel(
            body: "archiveNotificationMessageTitle".localized,
            notice: "archiveNotificationMessage".localized,
            queryParameter: "isArchive=1"
        ),
        PreviewModel(
            body: "notificationIcon".localized,
            notice: "notificationIconNotice".localized,
            queryParameter: "icon=https://day.app/assets/images/avatar.jpg",
            image: UIImage(named: "icon")
        ),
        PreviewModel(
            body: "messageGroup".localized,
            notice: "groupMessagesNotice".localized,
            queryParameter: "group=groupName",
            image: UIImage(named: "group")
        ),
        PreviewModel(
            body: "pushNotificationEncryption".localized,
            notice: "encryptionNotice".localized,
            queryParameter: "ciphertext=ciphertext",
            moreInfo: "encryptionSettings".localized,
            moreViewModel: CryptoSettingViewModel()
        ),
        PreviewModel(
            body: "criticalAlert".localized,
            notice: "criticalAlertNotice".localized,
            queryParameter: "level=critical&volume=5",
            image: UIImage(named: "criticalAlert")
        ),
        PreviewModel(
            body: "interruptionLevel".localized,
            notice: "interruptionLevelNotice".localized,
            queryParameter: "level=timeSensitive"
        ),
        PreviewModel(
            body: "URL Test",
            notice: "urlParameter".localized,
            queryParameter: "url=https://www.baidu.com"
        ),
        PreviewModel(
            body: "imagePushNotification".localized,
            notice: "imageParameter".localized,
            queryParameter: "image=https://day.app/assets/images/avatar.jpg"
        ),
        PreviewModel(
            body: "Copy Test",
            notice: "copyParameter".localized,
            queryParameter: "copy=test",
            image: UIImage(named: "copyTest")
        ),
        PreviewModel(
            body: "badge".localized,
            notice: "badgeNotice".localized,
            queryParameter: "badge=1"
        ),
        PreviewModel(
            body: "automaticallyCopyTitle".localized,
            notice: "automaticallyCopy".localized,
            queryParameter: "autoCopy=1&copy=optional"
        )
    ]
    
    /// 记录服务器错误的次数，如果错误次数大于2次，弹出提示引导用户查看FAQ。
    private var serverErrorCount = 0
    
    func transform(input: Input) -> Output {
        let title = BehaviorRelay(value: ServerManager.shared.currentServer.host)
        
        let sectionModel = SectionModel(
            model: "previews",
            items: previews.map { PreviewCardCellViewModel(previewModel: $0, clientState: input.clientState) }
        )
        
        // 点击跳转到添加自定义服务器
        let customServer = input.addCustomServerTap.map { NewServerViewModel() as ViewModel }
        
        // 如果更改了服务器地址，返回时也需更改 title
        customServer
            .flatMapLatest { model -> Driver<String> in
                (model as! NewServerViewModel).pop.asDriver(onErrorJustReturn: "")
            }
            .drive(title)
            .disposed(by: rx.disposeBag)

        // 点击preview中的notice ，跳转到对应的页面
        let noticeTap = Driver.merge(sectionModel.items.map { $0.noticeTap.asDriver(onErrorDriveWith: .empty()) })
        
        // 判断服务器状态
        let clienState = input.viewDidAppear
            .asObservable().flatMapLatest { _ -> Observable<Result<JSON, ApiError>> in
                BarkApi.provider
                    .request(.ping(baseURL: ServerManager.shared.currentServer.address))
                    .filterResponseError()
            }
            .map { response -> Client.ClienState in
                switch response {
                case .failure(let error):
                    return .serverError(error: error)
                default:
                    return .ok
                }
            }
        
        // 根据通知权限，设置是否隐藏注册按钮、显示示例预览列表
        let tableViewHidden = input.authorizationStatus.map { $0 == .authorized }
            .asObservable()
            .concat(
                input.start.asObservable().flatMapLatest { input.startRequestAuthorizationCreator() }
            )
            .asDriver(onErrorJustReturn: false)
        
        let showSnackbar = PublishRelay<String>()
        let alertServerError = PublishRelay<String>()
        
        // 点击注册按钮后，如果不允许推送，弹出提示
        tableViewHidden
            .skip(1)
            .compactMap { granted -> String? in
                if !granted {
                    return "AllowNotifications".localized
                }
                return nil
            }
            .asObservable()
            .bind(to: showSnackbar)
            .disposed(by: rx.disposeBag)
        
        // 点击注册按钮，如果用户允许推送，则通知 viewController 注册推送
        let registerForRemoteNotifications = tableViewHidden
            .skip(1)
            .filter { $0 }
            .map { _ in () }

        // client state 变化时，发出相应错误提醒
        input.clientState.drive(onNext: { [weak self] state in
            guard let self else { return }
            
            switch state {
            case .ok: break
            case .serverError(let error):
                if serverErrorCount < 2 {
                    showSnackbar.accept("\("ServerError".localized): \(error.rawString())")
                } else {
                    alertServerError.accept(error.rawString())
                }
                serverErrorCount += 1
            default: break
            }
            // 主要用于 url scheme 添加服务器时会有state状态改变事件，顺便更新下标题
            title.accept(ServerManager.shared.currentServer.host)
        })
        .disposed(by: rx.disposeBag)
        
        let serverList = input.serverListTap.map { ServerListViewModel() as ViewModel }
        
        // 服务器发生了改变
        serverList
            .flatMapLatest { model -> Driver<Server> in
                (model as! ServerListViewModel).currentServerChanged.asDriver(onErrorDriveWith: .empty())
            }
            .map { server -> String in
                server.host
            }
            .drive(title)
            .disposed(by: rx.disposeBag)
     
        return Output(
            previews: Driver.just([sectionModel]),
            push: Driver<ViewModel>.merge(customServer, noticeTap),
            present: serverList.asDriver(),
            title: title.asDriver(),
            clienStateChanged: clienState.asDriver(onErrorDriveWith: .empty()),
            tableViewHidden: tableViewHidden,
            showSnackbar: showSnackbar.asDriver(onErrorDriveWith: .empty()),
            alertServerError: alertServerError.asDriver(onErrorDriveWith: .empty()),
            startButtonEnable: Driver.just(true),
            copy: Driver.merge(sectionModel.items.map { $0.copy.asDriver(onErrorDriveWith: .empty()) }),
            preview: Driver.merge(sectionModel.items.map { $0.preview.asDriver(onErrorDriveWith: .empty()) }),
            reloadData: input.clientState.map { _ in () },
            registerForRemoteNotifications: registerForRemoteNotifications
        )
    }
}
