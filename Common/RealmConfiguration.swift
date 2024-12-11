//
//  RealmConfiguration.swift
//  NotificationServiceExtension
//
//  Created by huangfeng on 2024/5/29.
//  Copyright © 2024 Fin. All rights reserved.
//

@_exported import RealmSwift
import UIKit

let kRealmDefaultConfiguration = {
    let groupUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.bark")
    let fileUrl = groupUrl?.appendingPathComponent("bark.realm")
    let config = Realm.Configuration(
        fileURL: fileUrl,
        schemaVersion: 15,
        migrationBlock: { migration, oldSchemaVersion in
            switch oldSchemaVersion {
            case 0...13:
                migration.enumerateObjects(ofType: Message.className()) { oldObject, newObject in
                    guard let obj = oldObject else {
                        return
                    }
                    guard let isDeleted = obj["isDeleted"] as? Bool else {
                        return
                    }
                    // 旧版软删除的数据，迁移到新版时硬删除掉，新版不再过滤 isDeleted 字段
                    if isDeleted, let newObject {
                        migration.delete(newObject)
                    }
                }
            default:
                break
            }
        }
    )
    return config
}()
