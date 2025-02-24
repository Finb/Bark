//
//  ServerListTableViewCellViewModel.swift
//  Bark
//
//  Created by huangfeng on 2022/4/1.
//  Copyright © 2022 Fin. All rights reserved.
//

import RxRelay
import UIKit

class ServerListTableViewCellViewModel: ViewModel {
    let server: Server
    
    let name: BehaviorRelay<String>
    let key: BehaviorRelay<String>
    let state: BehaviorRelay<Bool>
    
    init(server: Server) {
        self.server = server
        
        self.name = BehaviorRelay<String>(value: {
            var serverName = URL(string: server.address)?.host ?? "Invalid Server"
            if let name = server.name, !name.isEmpty {
                serverName = name + "\n" + serverName
            }
            return serverName
        }())
        self.key = BehaviorRelay<String>(value: !server.key.isEmpty ? server.key : "none")
        self.state = BehaviorRelay<Bool>(value: server.state == .ok)
        
        super.init()
    }
}
