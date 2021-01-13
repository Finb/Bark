//
//  HomeViewModel.swift
//  Bark
//
//  Created by huangfeng on 2020/11/18.
//  Copyright © 2020 Fin. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import SwiftyJSON
import UserNotifications

class HomeViewModel: ViewModel, ViewModelType {
    struct Input {
        let addCustomServerTap: Driver<Void>
        let historyMessageTap: Driver<Void>
        let viewDidAppear: Driver<Void>
        let start: Driver<Void>
        let clientState: Driver<Client.ClienState>
    }
    struct Output {
        let previews: Driver<[SectionModel<String,PreviewCardCellViewModel>]>
        let push: Driver<ViewModel>
        let title: Driver<String>
        let clienStateChanged: Driver<Client.ClienState>
        let tableViewHidden: Driver<Bool>
        let showSnackbar: Driver<String>
        let startButtonEnable: Driver<Bool>
        let copy: Driver<String>
        let preview: Driver<URL>
        let reloadData: Driver<Void>
        let registerForRemoteNotifications: Driver<Void>
    }
    
    let previews:[PreviewModel] = {
        return [
            PreviewModel(
                body: NSLocalizedString("CustomedNotificationContent"),
                notice: NSLocalizedString("Notice1")),
            PreviewModel(
                title: NSLocalizedString("CustomedNotificationTitle"),
                body: NSLocalizedString("CustomedNotificationContent"),
                notice: NSLocalizedString("Notice2")),
            PreviewModel(
                body: NSLocalizedString("notificationSound"),
                notice: NSLocalizedString("setSounds"),
                queryParameter: "sound=minuet",
                moreInfo:NSLocalizedString("viewAllSounds"),
                moreViewModel: SoundsViewModel()
            ),
            PreviewModel(
                body: NSLocalizedString("archiveNotificationMessageTitle"),
                notice: NSLocalizedString("archiveNotificationMessage"),
                queryParameter: "isArchive=1"
                ),
            PreviewModel(
                body: "URL Test",
                notice: NSLocalizedString("urlParameter"),
                queryParameter: "url=https://www.baidu.com"
                ),
            PreviewModel(
                body: "Copy Test",
                notice: NSLocalizedString("copyParameter"),
                queryParameter: "copy=test",
                image: UIImage(named: "copyTest")
            ),
            PreviewModel(
                body: NSLocalizedString("automaticallyCopyTitle"),
                notice: NSLocalizedString("automaticallyCopy"),
                queryParameter: "automaticallyCopy=1&copy=optional"
            )
        ]
    }()

    func transform(input: Input) -> Output {
        
        let title = BehaviorRelay(value: URL(string: ServerManager.shared.currentAddress)?.host ?? "")
        
        let sectionModel = SectionModel(
            model: "previews",
            items: previews.map { PreviewCardCellViewModel(previewModel: $0, clientState: input.clientState) })
        
        
        //点击跳转到添加自定义服务器
        let customServer = input.addCustomServerTap.map{ NewServerViewModel() as ViewModel }
        
        //如果更改了服务器地址，返回时也需更改 title
        customServer
            .flatMapLatest({ (model) -> Driver<String> in
                return (model as! NewServerViewModel).pop.asDriver(onErrorJustReturn: "")
            })
            .drive(title)
            .disposed(by: rx.disposeBag)

        //点击跳转到历史通知
        let messageHistory = input.historyMessageTap.map{ MessageListViewModel() as ViewModel}
        //点击preview中的notice ，跳转到对应的页面
        let noticeTap = Driver.merge(sectionModel.items.map{ $0.noticeTap.asDriver(onErrorDriveWith: .empty()) })
        
        // 判断服务器状态
        let clienState = input.viewDidAppear
            .asObservable().flatMapLatest { _ -> Observable<Result<JSON,ApiError>> in
                BarkApi.provider
                    .request(.ping(baseURL: ServerManager.shared.currentAddress))
                    .filterResponseError()
            }
            .map { (response) -> Client.ClienState in
                switch response {
                case .failure:
                    return .serverError
                default:
                    return .ok
                }
            }
        
        //第一次进入APP 查看通知权限设置
        let authorizationStatus = Single<UNAuthorizationStatus>.create { (single) -> Disposable in
            UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                single(.success(settings.authorizationStatus))
            }
            return Disposables.create()
        }
        .map { $0 == .authorized}
        
        //点击注册按钮，请求通知权限
        let startRequestAuthorization = Single<Bool>.create { (single) -> Disposable in
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert , .sound , .badge], completionHandler: {(_ granted: Bool, _ error: Error?) -> Void in
                single(.success(granted))
            })
            return Disposables.create()
        }
        .asObservable()
        
        //根据通知权限，设置是否隐藏注册按钮、显示示例预览列表
        let tableViewHidden = authorizationStatus
            .asObservable()
            .concat(input.start
                        .asObservable()
                        .flatMapLatest{ startRequestAuthorization })
            .asDriver(onErrorJustReturn: false)
        
        
        let showSnackbar = PublishRelay<String>()
        
        //点击注册按钮后，如果不允许推送，弹出提示
        tableViewHidden
            .skip(1)
            .compactMap { (granted) -> String? in
                if !granted {
                    return NSLocalizedString("AllowNotifications")
                }
                return nil
            }
            .asObservable()
            .bind(to: showSnackbar)
            .disposed(by: rx.disposeBag)
        
        //点击注册按钮，如果用户允许推送，则通知 viewController 注册推送
        let registerForRemoteNotifications = tableViewHidden
            .skip(1)
            .filter{ $0 }
            .map{ _ in () }

        //client state 变化时，发出相应错误提醒
        input.clientState.drive(onNext: { state in
            switch state {
            case .ok:
                if let url = URL(string: ServerManager.shared.currentAddress) {
                    if url.scheme?.lowercased() != "https" {
                        showSnackbar.accept(NSLocalizedString("InsecureConnection"))
                    }
                }
            case .serverError:
                showSnackbar.accept(NSLocalizedString("ServerError"))
            default: break;
            }
        })
        .disposed(by: rx.disposeBag)
       
        return Output(
            previews:Driver.just([sectionModel]),
            push: Driver<ViewModel>.merge(customServer,messageHistory,noticeTap),
            title: title.asDriver(),
            clienStateChanged: clienState.asDriver(onErrorDriveWith: .empty()),
            tableViewHidden: tableViewHidden,
            showSnackbar: showSnackbar.asDriver(onErrorDriveWith: .empty()),
            startButtonEnable: Driver.just(true),
            copy: Driver.merge(sectionModel.items.map{ $0.copy.asDriver(onErrorDriveWith: .empty()) }),
            preview: Driver.merge(sectionModel.items.map{ $0.preview.asDriver(onErrorDriveWith: .empty()) }),
            reloadData: input.clientState.map{ _ in ()},
            registerForRemoteNotifications: registerForRemoteNotifications
        )
    }
    
}
