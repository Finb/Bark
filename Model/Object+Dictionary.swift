//
//  Object+Dictionary.swift
//  Bark
//
//  Created by huangfeng on 2022/10/20.
//  Copyright © 2022 Fin. All rights reserved.
//

import Foundation
import RealmSwift

extension Object {
    func toDictionary() -> [String: AnyObject] {
        let properties = self.objectSchema.properties.map { $0.name }
        var dicProps = [String: AnyObject]()
        for (key, value) in self.dictionaryWithValues(forKeys: properties) {
            if let value = value as? ListBase {
                dicProps[key] = value.toArray1() as AnyObject
            } else if let value = value as? Object {
                dicProps[key] = value.toDictionary() as AnyObject
            } else if let value = value as? Date {
                dicProps[key] = Int64(value.timeIntervalSince1970) as AnyObject
            } else {
                dicProps[key] = value as AnyObject
            }
        }
        return dicProps
    }
}

extension ListBase {
    func toArray1() -> [AnyObject] {
        var _toArray = [AnyObject]()
        for i in 0 ..< self._rlmArray.count {
            let obj = unsafeBitCast(self._rlmArray[i], to: Object.self)
            _toArray.append(obj.toDictionary() as AnyObject)
        }
        return _toArray
    }
}
