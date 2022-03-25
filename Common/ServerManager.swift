//
//  ServerManager.swift
//  Bark
//
//  Created by huangfeng on 2018/3/21.
//  Copyright © 2018年 Fin. All rights reserved.
//

import RxSwift
import SwiftUI
import UIKit

let defaultServer = "https://api.day.app"

class Server: Codable {
    let id: String
    let address: String
    var key: String
    var state: Client.ClienState
    init(id: String = UUID().uuidString, address: String, key: String, state: Client.ClienState = .ok) {
        self.id = id
        self.address = address
        self.key = key
        self.state = state
    }
}

class ServerManager: NSObject {
    static let shared = ServerManager()
    override private init() {
        if let servers: [Server] = Settings[.servers] {
            self.servers = servers
        }

        if servers.count <= 0 {
            servers = [Server(id: UUID().uuidString, address: defaultServer, key: "")]
        }
        self.currentServer = servers[0]

        super.init()

        // 将老版本数据转换成新版本
        if let address = Settings[.currentServer] {
            let key = Settings[.key] ?? ""
            let server = Server(id: UUID().uuidString, address: address, key: key)

            self.servers = []
            self.addServer(server: server)

            Settings[.currentServerId] = server.id

            // 清空老版本数据
            Settings[.currentServer] = nil
            Settings[.key] = nil
        }

        if let currentServerId = Settings[.currentServerId] {
            self.setCurrentServer(serverId: currentServerId)
        }
    }

    /// 所有的 server
    var servers: [Server] = []
    /// 当前选中的 server ，在教程页显示。
    private(set) var currentServer: Server

    /// 更改当前选中的 server
    func setCurrentServer(serverId: String) {
        if let server = servers.first(where: { $0.id == serverId }) {
            currentServer = server
        }
        else {
            currentServer = servers.first!
        }
        Settings[.currentServerId] = serverId
    }

    /// 添加新的 server
    func addServer(server: Server) {
        self.servers.append(server)
        saveServers()
    }

    /// 移除 server，移除后如果 server 为`空`, `会新增一个默认server`
    func removeServer(server: Server) {
        self.servers.removeAll { $0.id == server.id }
        if self.servers.count <= 0 {
            self.servers.append(
                Server(id: UUID().uuidString, address: defaultServer, key: "")
            )
            self.setCurrentServer(serverId: self.servers[0].id)
        }
        saveServers()
    }

    /// 保存 servers
    func saveServers() {
        Settings[.servers] = self.servers
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var dispose: Disposable?
    /// 同步所有 server
    func syncAllServers() {
        guard let token = Client.shared.deviceToken.value, token.count > 0 else {
            return
        }
        dispose?.dispose()

        let apis = servers.map { server in
            BarkApi.provider.request(
                .register(
                    address: server.address,
                    key: server.key,
                    devicetoken: token))
                .filterResponseError()
                .map { result -> (Server, String, Client.ClienState) in

                    switch result {
                    case .success(let json):
                        if let key = json["data", "key"].rawString() {
                            return (server, key, .ok)
                        }
                        else {
                            return (server, "", .serverError)
                        }
                    case .failure:
                        return (server, "", .serverError)
                    }
                }.catch { _ in
                    Observable.just((server, "", .serverError))
                }
        }

        dispose = Observable
            .merge(apis)
            .subscribe { result in
                // 更新所有的 server 状态
                result.0.key = result.1
                result.0.state = result.2

                // 通知客户端 当前 server 状态改变
                if result.0.id == self.currentServer.id {
                    Client.shared.state.accept(result.2)
                }
            } onError: { _ in

            } onCompleted: {
                self.saveServers()
            }
    }
}
