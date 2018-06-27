//
//  BarkApi.swift
//  Bark
//
//  Created by huangfeng on 2018/6/25.
//  Copyright © 2018 Fin. All rights reserved.
//

import UIKit

enum BarkApi {
    case ping(baseURL:String?)
    case register(key:String? , devicetoken:String) //注册设备
}

extension BarkApi: BarkTargetType {
    var baseURL: URL {
        if case let .ping(urlStr) = self, let url = URL(string: urlStr ?? "")  {
            return url
        }
        return URL(string: ServerManager.shared.currentAddress)!
    }
    var parameters: [String : Any]? {
        switch self {
        case let .register(key, devicetoken):
            var params = ["devicetoken":devicetoken]
            if let key = key {
                params["key"] = key
            }
            return params
        default:
            return nil
        }
    }
    
    var path: String {
        switch self {
        case .ping:
            return "/ping"
        case .register:
            return "/register"
        }
    }
    
    
}
