//
//  ServerManager.swift
//  Bark
//
//  Created by huangfeng on 2018/3/21.
//  Copyright © 2018年 Fin. All rights reserved.
//

import UIKit

let defaultServer = "https://api.day.app"

class ServerManager: NSObject {
    static let shared = ServerManager()
    private override init() {
        if let servers:Set<String> = Settings[.servers] {
            self.servers = servers
        }
        
        if let address = Settings[.currentServer] {
            self.currentAddress = address
        }
        else{
            self.currentAddress = self.servers.first ?? defaultServer
        }
        super.init()
    }
    
    var servers:Set<String> = [defaultServer]
    var currentAddress:String {
        didSet{
            Settings[.currentServer] = currentAddress
        }
    }
    
    func addServer(server:String){
        self.servers.insert(server)
        Settings[.servers] = self.servers
    }
    func removeServer(server:String){
        self.servers.remove(server)
        if self.servers.count <= 0 {
            self.servers.insert(defaultServer)
        }
        Settings[.servers] = self.servers
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
