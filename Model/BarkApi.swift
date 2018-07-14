//
//  BarkApi.swift
//  Bark
//
//  Created by huangfeng on 2018/6/25.
//  Copyright © 2018 Fin. All rights reserved.
//

import UIKit
import Moya
import Alamofire

enum BarkApi {
    case ping(baseURL:String?)
    case register(key:String? , device_token:String) //注册设备
}

extension BarkApi: BarkTargetType {
    var baseURL: URL {
        if case let .ping(urlStr) = self, let url = URL(string: urlStr ?? "")  {
            return url
        }
        return URL(string: ServerManager.shared.currentAddress)!
    }
    var method: Moya.Method {
        switch self {
        case .register:
            return .post
        default:
            return .get
        }
    }
    
    var headers: [String: String]? {
        return ["Content-Type": "application/json"]
    }
    
    var task: Task {
        switch self {
        case .register(let _, let device_token):
            return .requestParameters(parameters: ["device_token": device_token], encoding: Alamofire.JSONEncoding.default)
        default:
            return .requestParameters(parameters: [:], encoding: URLEncoding.default)
        }
    }

    var parameters: [String : Any]? {
        switch self {
        case let .register(key, device_token):
            var params = ["device_token":device_token]
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
