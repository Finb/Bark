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
    
    let address: BehaviorRelay<String>
    let key: BehaviorRelay<String>
    let state: BehaviorRelay<Bool>
    
    init(server: Server) {
        self.server = server
        
        self.address = BehaviorRelay<String>(value: {
            URL(string: server.address)?.host ?? "Invalid Server"
        }())
        self.key = BehaviorRelay<String>(value: !server.key.isEmpty ? server.key : "none")
        self.state = BehaviorRelay<Bool>(value: server.state == .ok)
        
        super.init()
    }
}
