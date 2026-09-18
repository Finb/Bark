//
//  ServerManager.swift
//  Bark
//
//  Created by huangfeng on 2018/3/21.
//  Copyright © 2018年 Fin. All rights reserved.
//

import RxCocoa
import RxSwift
import SwiftUI
import UIKit

let defaultServer = "https://api.day.app"

class Server: Codable {
    let id: String
    let address: String
    var key: String
    var name: String?
    
    var host: String {
        return URL(string: address)?.host ?? ""
    }
    
    init(id: String = UUID().uuidString, address: String, key: String) {
        self.id = id
        self.address = address
        self.key = key
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case address
        case key
        case name
    }
    
    // 解码
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        address = try container.decode(String.self, forKey: .address)
        key = try container.decode(String.self, forKey: .key)
        name = try? container.decode(String?.self, forKey: .name)
    }
}

class ServerManager: NSObject {
    static let shared = ServerManager()
    override private init() {
        var servers: [Server] = []
        if let savedServers: [Server] = Settings[.servers] {
            servers = savedServers
        }

        if servers.count <= 0 {
            servers = [Server(id: UUID().uuidString, address: defaultServer, key: "")]
        }
        self.servers = servers
        let initialServer = servers[0]
        self.currentServer = initialServer

        super.init()

        // 将老版本数据转换成新版本
        if let key = Settings[.key] {
            let address = Settings[.currentServer] ?? defaultServer
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
    private(set) var currentServer: Server {
        didSet {
            currentServerUpdateRelay.accept(currentServer)
        }
    }
    let currentServerUpdateRelay = PublishRelay<Server>()

    /// 更改当前选中的 server
    func setCurrentServer(serverId: String) {
        if let server = servers.first(where: { $0.id == serverId }) {
            currentServer = server
        } else {
            currentServer = servers.first!
        }
        Settings[.currentServerId] = serverId
    }

    /// 添加新的 server
    func addServer(server: Server) {
        self.servers.append(server)
        saveServers()
    }

    func updateServerKey(server: Server) {
        let foundServer = self.servers.first { $0.id == server.id }
        foundServer?.key = server.key
        saveServers()
        // 主要用于更新首页示例中的 key
        if server.id == currentServer.id {
            currentServerUpdateRelay.accept(currentServer)
        }
    }
    
    /// 移除 server，移除后如果 server 为`空`, `会新增一个默认server`
    func removeServer(server: Server) {
        self.servers.removeAll { $0.id == server.id }
        if self.servers.count <= 0 {
            self.servers.append(
                Server(id: UUID().uuidString, address: defaultServer, key: "")
            )
        }
        if self.currentServer.id == server.id {
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
                    devicetoken: token
                ))
                .filterResponseError()
                .map { result -> (Server, String?) in

                    switch result {
                    case .success(let json):
                        return (server, json["data", "key"].rawString())
                    case .failure:
                        return (server, nil)
                    }
                }.catch { _ in
                    Observable.just((server, nil))
                }
        }

        dispose = Observable
            .merge(apis)
            .subscribe { result in
                // 更新所有的 server key
                if let key = result.1 {
                    result.0.key = key
                    if result.0.id == self.currentServer.id {
                        self.currentServerUpdateRelay.accept(result.0)
                    }
                }
            } onError: { _ in

            } onCompleted: {
                self.saveServers()
            }
    }
    
    func setServerName(server: Server, name: String?) {
        server.name = name
        saveServers()
    }
}
