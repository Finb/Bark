//
//  Error+Extension.swift
//  Bark
//
//  Created by huangfeng on 2023/3/3.
//  Copyright © 2023 Fin. All rights reserved.
//

import Foundation

extension String: @retroactive Error {}

// 桥接 NSError 后 localizedDescription 默认是占位文案，AppIntents 等系统组件以此展示错误
extension String: @retroactive LocalizedError {
    public var errorDescription: String? { self }
}

public enum ApiError: Swift.Error {
    case Error(info: String)
    case AccountBanned(info: String)
}

extension Swift.Error {
    func rawString() -> String {
        if let err = self as? String {
            return err
        }
        guard let err = self as? ApiError else {
            return self.localizedDescription
        }
        switch err {
        case .Error(let info):
            return info
        case .AccountBanned(let info):
            return info
        }
    }
}
