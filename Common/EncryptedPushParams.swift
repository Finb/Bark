//
//  EncryptedPushParams.swift
//  Bark
//
//  Copyright © 2026 Fin. All rights reserved.
//

import Foundation

enum EncryptedPushParams {
    /// GCM 的 iv 取字符串的 UTF-8 字节，长度需为 12
    private static let ivLength = 12
    private static let ivCharacters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")

    /// 把推送参数加密为 ciphertext 请求参数。仅支持 GCM。
    static func encrypt(params: [String: Any], fields: CryptoSettingFields) throws -> [String: String] {
        guard fields.mode == "GCM" else {
            throw "encryptedPushRequiresGCM".localized
        }

        // 每次推送使用随机 iv，随请求一起发送，接收端以该 iv 解密
        let iv = randomIV()
        var fields = fields
        fields.iv = iv

        let json = try JSONSerialization.data(withJSONObject: params)
        let aes = try AESCryptoModel(cryptoFields: fields)
        let ciphertext = try aes.encrypt(text: String(decoding: json, as: UTF8.self))

        return ["ciphertext": ciphertext, "iv": iv]
    }

    /// 构建加密推送的请求参数。ttl 需服务端读取（设置 APNs 过期时间），保持明文透传，不进密文。
    static func requestParams(params: [String: Any], fields: CryptoSettingFields) throws -> [String: Any] {
        var payload = params
        let ttl = payload.removeValue(forKey: "ttl")

        var result: [String: Any] = try encrypt(params: payload, fields: fields)
        if let ttl {
            result["ttl"] = ttl
        }
        return result
    }

    /// 用一次性密钥构建加密推送的请求参数，密钥长度决定 AES 位数，模式固定 GCM。
    static func requestParams(params: [String: Any], encryptionKey: String) throws -> [String: Any] {
        let algorithms: [Int: Algorithm] = [16: .aes128, 24: .aes192, 32: .aes256]
        guard let algorithm = algorithms[encryptionKey.count] else {
            throw "encryptionKeyLengthInvalid".localized
        }

        let fields = CryptoSettingFields(
            algorithm: algorithm.rawValue,
            mode: "GCM",
            padding: "noPadding",
            key: encryptionKey,
            iv: nil
        )
        return try requestParams(params: params, fields: fields)
    }

    private static func randomIV() -> String {
        String((0 ..< ivLength).map { _ in ivCharacters[Int.random(in: ivCharacters.indices)] })
    }
}
