//
//  BarkApi.swift
//  Bark
//
//  Created by huangfeng on 2018/6/25.
//  Copyright © 2018 Fin. All rights reserved.
//

import Moya
import UIKit

enum BarkApi {
    case ping(baseURL: String?)
    case register(address: String, key: String?, devicetoken: String) // 注册设备
    case rotateKey(address: String, key: String, deviceToken: String) // 轮换设备 key（需要 deviceToken 证明所有权）
}

extension BarkApi: BarkTargetType {
    var baseURL: URL {
        switch self {
        case let .ping(urlStr):
            if let url = URL(string: urlStr ?? "") {
                return url
            }
        case let .register(address, _, _):
            if let url = try? address.asURL() {
                return url
            }
        case let .rotateKey(address, _, _):
            if let url = try? address.asURL() {
                return url
            }
        }
        return try! ServerManager.shared.currentServer.address.asURL()
    }

    var parameters: [String: Any]? {
        switch self {
        case let .register(_, key, devicetoken):
            var params = ["devicetoken": devicetoken]
            if let key = key {
                params["key"] = key
            }
            return params
        case let .rotateKey(_, key, deviceToken):
            return ["device_key": key, "device_token": deviceToken]
        default:
            return nil
        }
    }

    var method: Moya.Method {
        switch self {
        case .rotateKey:
            return .post
        default:
            return .get
        }
    }

    var parameterEncoding: ParameterEncoding {
        switch self {
        case .rotateKey:
            return JSONEncoding.default
        default:
            return URLEncoding.default
        }
    }

    var path: String {
        switch self {
        case .ping:
            return "/ping"
        case .register:
            return "/register"
        case .rotateKey:
            return "/register/rotate"
        }
    }
}
