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
        schemaVersion: 13,
        migrationBlock: { _, oldSchemaVersion in
            // We haven’t migrated anything yet, so oldSchemaVersion == 0
            if oldSchemaVersion < 1 {
                // Nothing to do!
                // Realm will automatically detect new properties and removed properties
                // And will update the schema on disk automatically
            }
        }
    )
    return config
}()
