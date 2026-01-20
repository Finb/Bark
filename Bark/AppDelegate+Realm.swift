//
//  AppDelegate+Realm.swift
//  Bark
//
//  Created by huangfeng on 12/18/25.
//  Copyright © 2025 Fin. All rights reserved.
//

import UIKit

extension AppDelegate {
    /*
     之前数据库是放在App Groups 共享
     但由于Realm无法解决 0xdead10cc 闪退问题
     因此改为在主APP中存放数据库文件
     Notification Service Extension 使用 plist 文件保存消息，供主APP读取存放到数据库中
     */
    func setupRealm() {
        // 先执行数据库迁移
        migrateRealmDatabase()
        
        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = kRealmDefaultConfiguration
    }

    func migrateRealmDatabase() {
        // 检查是否已经迁移过
        if UserDefaults.standard.bool(forKey: "hasRealmMigrated") {
            return
        }
        
        let fileManager = FileManager.default
        guard let oldGroupUrl = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.bark"),
              let newDocUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        else {
            return
        }
        
        let oldRealmUrl = oldGroupUrl.appendingPathComponent("bark.realm")
        let newRealmUrl = newDocUrl.appendingPathComponent("bark.realm")
        
        // 检查旧文件是否存在
        guard fileManager.fileExists(atPath: oldRealmUrl.path) else {
            // 旧文件不存在，标记为已迁移
            UserDefaults.standard.set(true, forKey: "hasRealmMigrated")
            return
        }
        
        do {
            // 复制主数据库文件
            try fileManager.copyItem(at: oldRealmUrl, to: newRealmUrl)
            
            // 复制相关文件
            let relatedFiles = ["bark.realm.lock", "bark.realm.management", "bark.realm.note"]
            for file in relatedFiles {
                let oldUrl = oldGroupUrl.appendingPathComponent(file)
                let newUrl = newDocUrl.appendingPathComponent(file)
                if fileManager.fileExists(atPath: oldUrl.path) {
                    try? fileManager.copyItem(at: oldUrl, to: newUrl)
                }
            }
            
            // 删除旧文件
            try fileManager.removeItem(at: oldRealmUrl)
            for file in relatedFiles {
                let oldUrl = oldGroupUrl.appendingPathComponent(file)
                try? fileManager.removeItem(at: oldUrl)
            }
            
            // 标记为已迁移
            UserDefaults.standard.set(true, forKey: "hasRealmMigrated")
        } catch {
            // 迁移失败，弹出提示
            DispatchQueue.main.async {
                let alert = UIAlertController(
                    title: "Migration Failed",
                    message: "Failed to migrate database file. Please contact support.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.window?.rootViewController?.present(alert, animated: true)
            }
        }
    }
    
    // 处理 Notification Service Extension 保存的待处理消息, 将其存入 Realm 数据库
    func processPendingMessages() {
        guard let groupUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.bark") else {
            return
        }
        
        let pendingMessagesDir = groupUrl.appendingPathComponent("pending_messages")
        
        // 检查目录是否存在
        guard FileManager.default.fileExists(atPath: pendingMessagesDir.path) else {
            return
        }
        
        // 获取所有 plist 文件
        guard let fileUrls = try? FileManager.default.contentsOfDirectory(
            at: pendingMessagesDir,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return
        }
        
        let plistFiles = fileUrls.filter { $0.pathExtension == "plist" }
        
        guard !plistFiles.isEmpty else {
            return
        }
        
        // 获取 Realm 实例
        guard let realm = try? Realm() else {
            return
        }
        
        // 批量处理消息
        var messagesToAdd: [Message] = []
        var urlsToDelete: [URL] = []
        
        // 先读取所有 plist 文件
        for plistUrl in plistFiles {
            guard let dict = NSDictionary(contentsOf: plistUrl) as? [String: Any] else {
                continue
            }
            
            let message = Message(dict: dict)
            messagesToAdd.append(message)
            urlsToDelete.append(plistUrl)
        }
        
        // 批量写入 Realm
        do {
            try realm.write {
                for message in messagesToAdd {
                    realm.add(message, update: .all)
                }
            }
        } catch {
            // 一般不会失败，真失败了算你小子运气差
        }
        
        // 无论成功或失败，都删除已处理的 plist 文件
        for plistUrl in urlsToDelete {
            try? FileManager.default.removeItem(at: plistUrl)
        }
    }
}
