//
//  ServerListViewModel.swift
//  Bark
//
//  Created by huangfeng on 2022/3/25.
//  Copyright © 2022 Fin. All rights reserved.
//

import Differentiator
import Foundation
import Moya
import RxCocoa
import RxSwift
import SwiftyJSON

class ServerListViewModel: ViewModel, ViewModelType {
    struct Input {
        let selectServer: Driver<Server>
        let copyServer: Driver<Server>
        let deleteServer: Driver<Server>
        let resetServer: Driver<(Server, String?)>
        let setServerName: Driver<(Server, String?)>
    }

    struct Output {
        let servers: Driver<[SectionModel<String, ServerListTableViewCellViewModel>]>
        let showSnackbar: Driver<String>
        let copy: Driver<String>
    }

    let currentServerChanged = PublishRelay<Server>()

    func transform(input: Input) -> Output {
        // 弹出提示消息
        let showSnackbar = PublishRelay<String>()

        // 复制 Server
        let copy = input.copyServer.map { server -> String in
            "\(server.address)/\(server.key)/"
        }
        
        // 设置服务器名称
        input.setServerName.drive(onNext: { server, name in
            ServerManager.shared.setServerName(server: server, name: name)
        }).disposed(by: rx.disposeBag)

        // 删除检查，需要至少保留一个服务器
        let deleteCheck = input.deleteServer.map { server -> Server? in
            if ServerManager.shared.servers.count > 1 {
                return server
            }
            return nil
        }.asObservable().share()

        // 删除检查错误提示
        deleteCheck.filter { $0 == nil }
            .map { _ in NSLocalizedString("deleteFailed") }
            .bind(to: showSnackbar)
            .disposed(by: rx.disposeBag)

        // 对即将删除的服务器发送错误的 deviceToken，防止服务器依然保留旧的推送链接。
        let delete = deleteCheck.compactMap { $0 }
            .flatMapLatest { server -> Observable<Result<JSON, ApiError>>in
                if server.key.count > 0 {
                    return BarkApi.provider
                        .request(.register(address: server.address, key: server.key, devicetoken: "deleted"))
                        .filterResponseError()
                }
                return Observable.just(Result<JSON, ApiError>.success(JSON()))
                    .delay(.milliseconds(300), scheduler: MainScheduler.instance)
            }

        // 服务器远程注销后，再本地删除
        // withLatestFrom 将在 delete 产生新的事件时,
        // 取 input.deleteServer 最后一个事件的元素。（这里是对应的 server ）
        let serverDeleted = delete.withLatestFrom(input.deleteServer)
            .map { server in
                ServerManager.shared.removeServer(server: server)
            }.share()

        // 弹出删除提示
        serverDeleted.map { NSLocalizedString("deletedSuccessfully") }
            .bind(to: showSnackbar)
            .disposed(by: rx.disposeBag)

        // 重置服务器之前，先检查 DeviceToken
        let resetServer = input.resetServer
            .map { ($0.0, $0.1, Client.shared.deviceToken.value) }
            .asObservable().share()

        // 重置检查错误提示
        resetServer.filter { ($0.2?.count ?? 0) <= 0 }
            .map { _ in NSLocalizedString("resetFailed2") }
            .bind(to: showSnackbar)
            .disposed(by: rx.disposeBag)

        // 对重置的旧 key 发送错误的 deviceToken, 使其失效。
        resetServer.filter { ($0.2?.count ?? 0) > 0 && $0.0.key.count > 0 }.flatMapLatest {
            BarkApi.provider
                .request(.register(address: $0.0.address, key: $0.0.key, devicetoken: "deleted"))
                .filterResponseError()
        }
        .subscribe()
        .disposed(by: rx.disposeBag)

        // 发送重置请求
        let serverReseted = resetServer.filter { ($0.2?.count ?? 0) > 0 }
            .flatMapLatest { r -> Observable<Result<JSON, ApiError>> in
                let server = r.0
                let newKey = r.1
                let deviceToken = r.2!
                return BarkApi.provider
                    .request(.register(address: server.address, key: newKey, devicetoken: deviceToken))
                    .filterResponseError()
            }
            .map { result -> String? in
                switch result {
                case .success(let json):
                    return json["data", "key"].rawString()
                case .failure:
                    return nil
                }
            }.share()

        // 重置成功后，更新本地服务器列表
        let serverResetSuccess = serverReseted.compactMap { $0 }.withLatestFrom(input.resetServer) { newKey, r in
            let server = r.0
            server.key = newKey
            ServerManager.shared.updateServerKey(server: server)
        }.share()

        // 重置失败提示
        serverReseted.filter { $0 == nil }
            .map { _ in NSLocalizedString("resetFailed") }
            .bind(to: showSnackbar)
            .disposed(by: rx.disposeBag)

        // 服务器列表
        let servers = Observable
            .merge(
                Observable.just(()),
                serverDeleted,
                serverResetSuccess,
                input.setServerName.map { _ in () }.asObservable()
            )
            .map {
                [SectionModel(
                    model: "servers",
                    items: ServerManager.shared.servers.map { ServerListTableViewCellViewModel(server: $0) }
                )]
            }.asDriver(onErrorDriveWith: .empty())

        // 选择首页预览服务器
        let serverSelected = input.selectServer.asObservable().map { server in
            ServerManager.shared.setCurrentServer(serverId: server.id)
            showSnackbar.accept(NSLocalizedString("setSuccessfully"))
            return ()
        }
        
        // 当前服务器有改动
        let serverChanged = Observable.merge(serverSelected, serverDeleted, serverResetSuccess)
            .share()

        serverChanged.map {
            ServerManager.shared.currentServer
        }
        .bind(to: self.currentServerChanged)
        .disposed(by: rx.disposeBag)

        // 服务器改变时，同步 Client.shared.state。
        serverChanged.map {
            ServerManager.shared.currentServer.state
        }
        .bind(to: Client.shared.state)
        .disposed(by: rx.disposeBag)

        return Output(
            servers: servers,
            showSnackbar: showSnackbar.asDriver(onErrorDriveWith: .empty()),
            copy: copy
        )
    }
}
