//
//  WatchEncryption.swift — watch storage and notification presentation
//  Bark
//
//  Created by huangfeng on 2023/2/23.
//  Copyright © 2023 Fin. All rights reserved.
//

import Foundation
import CryptoSwift
import Security
import UserNotifications

nonisolated struct WatchCryptoError: LocalizedError {
    let errorDescription: String?
    init(_ message: String) { errorDescription = message }
}

// Same Codable settings as the phone, stored in a shared Keychain item on the watch.
nonisolated enum WatchCryptoStore {
    private static func query(account: String) throws -> [String: Any] {
        guard let group = Bundle.main.object(forInfoDictionaryKey: "BarkKeychainAccessGroup") as? String,
              !group.isEmpty, !group.contains("$(") else {
            throw WatchCryptoError("Encryption key sharing is not configured in this build.")
        }
        return [kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: "BarkWatchEncryption",
                kSecAttrAccount as String: account, kSecAttrAccessGroup as String: group]
    }

    static func load(account: String = "settings") throws -> CryptoSettingFields? {
        var query = try query(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        try check(status)
        guard let data = result as? Data else { throw WatchCryptoError("Cannot read encryption settings.") }
        return try JSONDecoder().decode(CryptoSettingFields.self, from: data)
    }

    static func save(_ fields: CryptoSettingFields?, account: String = "settings") throws {
        let query = try query(account: account)
        guard let fields else {
            let status = SecItemDelete(query as CFDictionary)
            if status != errSecItemNotFound { try check(status) }
            return
        }
        try WatchEncryption.validate(fields)
        if let iv = fields.iv, !iv.isEmpty { _ = try AESCryptoModel(watchFields: fields) }
        let values: [String: Any] = [kSecValueData as String: try JSONEncoder().encode(fields),
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
        let status = SecItemUpdate(query as CFDictionary, values as CFDictionary)
        if status == errSecItemNotFound {
            try check(SecItemAdd(query.merging(values) { _, value in value } as CFDictionary, nil))
        } else { try check(status) }
    }

    private static func check(_ status: OSStatus) throws {
        guard status == errSecSuccess else {
            throw WatchCryptoError("Keychain error: \(status).")
        }
    }
}

nonisolated enum WatchEncryption {
    static func validate(_ fields: CryptoSettingFields) throws {
        guard let algorithm = Algorithm(rawValue: fields.algorithm) else {
            throw WatchCryptoError("Invalid algorithm")
        }
        guard let key = fields.key, key.utf8.count == algorithm.keyLength else {
            throw WatchCryptoError("The key must contain \(algorithm.keyLength) UTF-8 bytes.")
        }
        guard algorithm.modes.contains(fields.mode) else { throw WatchCryptoError("Invalid Mode") }
        guard ["noPadding", "pkcs7"].contains(fields.padding) else { throw WatchCryptoError("Invalid Padding") }
        if fields.mode == "GCM", fields.padding != "noPadding" {
            throw WatchCryptoError("GCM requires noPadding.")
        }
    }

    static func decryptPayload(_ ciphertext: String, fields: CryptoSettingFields) throws -> [AnyHashable: Any] {
        let base64 = ciphertext.components(separatedBy: .whitespacesAndNewlines).joined()
        guard let encoded = Data(base64Encoded: base64), !encoded.isEmpty else {
            throw WatchCryptoError("Invalid ciphertext")
        }
        let json = try AESCryptoModel(watchFields: fields).decrypt(ciphertext: base64)
        guard let map = try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any] else {
            throw WatchCryptoError("Decrypted content must be a JSON object.")
        }
        var result: [AnyHashable: Any] = [:]
        for (key, value) in map {
            let key = key.lowercased()
            guard result[key] == nil else { throw WatchCryptoError("Duplicate notification field") }
            result[key] = (value as? NSNumber)?.stringValue ?? value
        }
        return result
    }

    static func randomText(length: Int) throws -> String {
        if length == 0 { return "" }
        var bytes = [UInt8](repeating: 0, count: length)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else {
            throw WatchCryptoError("Could not generate random bytes.")
        }
        let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_".utf8)
        return String(decoding: bytes.map { alphabet[Int($0 & 63)] }, as: UTF8.self)
    }

    static func encrypt(_ payload: [String: String], fields: CryptoSettingFields) throws -> [String: String] {
        var fields = fields
        fields.iv = try randomText(length: fields.mode == "GCM" ? 12 : fields.mode == "CBC" ? 16 : 0)
        let data = try JSONEncoder().encode(payload)
        let cipher = try AESCryptoModel(watchFields: fields).encrypt(text: String(decoding: data, as: UTF8.self))
        var result = ["ciphertext": cipher]
        if let iv = fields.iv, !iv.isEmpty { result["iv"] = iv }
        return result
    }

    // Decode with the phone model, then apply watch-specific notification defaults.
    static func decrypt(_ content: UNMutableNotificationContent, fields: CryptoSettingFields?) throws {
        guard content.userInfo["ciphertext"] != nil else { return }
        guard let ciphertext = content.userInfo["ciphertext"] as? String, var fields else {
            throw WatchCryptoError("No encryption key set, or invalid ciphertext.")
        }
        if let value = content.userInfo["iv"] {
            guard let iv = value as? String else { throw WatchCryptoError("Invalid initialization vector") }
            fields.iv = iv
        }
        var result = try decryptPayload(ciphertext, fields: fields)
        content.title = result["title"] as? String ?? ""
        content.subtitle = result["subtitle"] as? String ?? ""
        content.body = result["body"] as? String ?? ""
        content.threadIdentifier = result["group"] as? String ?? ""
        content.attachments = []
        content.interruptionLevel = .active
        content.sound = .default
        content.badge = nil
        result["aps"] = ["alert": ["title": content.title, "subtitle": content.subtitle, "body": content.body],
                         "sound": result["sound"] as? String ?? "default"]
        content.userInfo = result
    }

    static func prepare(_ content: UNMutableNotificationContent, fields: () throws -> CryptoSettingFields?) -> Bool {
        guard content.userInfo["ciphertext"] != nil else { return true }
        do {
            try decrypt(content, fields: fields())
            return true
        } catch {
            // Do not display outer plaintext fields or process outer image/icon URLs on failure.
            content.title = "Bark"
            content.subtitle = ""
            content.body = "Decryption Failed"
            content.threadIdentifier = ""
            content.attachments = []
            content.sound = .default
            content.interruptionLevel = .active
            content.badge = nil
            content.userInfo = ["aps": ["alert": ["body": content.body]]]
            return false
        }
    }
}

// Extend the phone model with byte-based validation without changing its source.
extension AESCryptoModel {
    init(watchFields fields: CryptoSettingFields) throws {
        try WatchEncryption.validate(fields)
        let key = fields.key!
        let vectorLength = fields.mode == "CBC" ? 16 : fields.mode == "GCM" ? 12 : 0
        if vectorLength > 0, fields.iv?.utf8.count != vectorLength {
            throw WatchCryptoError("The initialization vector must contain \(vectorLength) UTF-8 bytes.")
        }
        let mode: BlockMode
        switch fields.mode {
        case "CBC": mode = CBC(iv: Array(fields.iv!.utf8))
        case "GCM": mode = GCM(iv: Array(fields.iv!.utf8), mode: .combined)
        default: mode = ECB()
        }
        self.key = key
        self.mode = mode
        self.padding = fields.padding == "noPadding" ? .noPadding : .pkcs7
        self.aes = try AES(key: Array(key.utf8), blockMode: mode, padding: padding)
    }
}
