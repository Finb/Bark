//
//  Algorithm.swift
//  Bark
//
//  Created by huangfeng on 2023/2/23.
//  Copyright © 2023 Fin. All rights reserved.
//

import CryptoSwift
import Foundation

enum Algorithm: String {
    case aes128 = "AES128"
    case aes192 = "AES192"
    case aes256 = "AES256"

    var modes: [String] {
        switch self {
        case .aes128, .aes192, .aes256:
            return ["CBC", "ECB", "GCM"]
        }
    }

    var keyLength: Int {
        switch self {
        case .aes128:
            return 16
        case .aes192:
            return 24
        case .aes256:
            return 32
        }
    }
}

struct CryptoSettingFields: Codable {
    let algorithm: String
    let mode: String
    let padding: String
    let key: String?
    var iv: String?
}

struct AESCryptoModel {
    let key: String
    let mode: BlockMode
    let padding: Padding
    let aes: AES

    @discardableResult
    static func validate(cryptoFields: CryptoSettingFields) throws -> String {
        guard let algorithm = Algorithm(rawValue: cryptoFields.algorithm) else {
            throw "Invalid algorithm"
        }
        guard let key = cryptoFields.key, algorithm.keyLength == key.count else {
            throw String(format: "enterKey".localized, algorithm.keyLength)
        }
        guard algorithm.modes.contains(cryptoFields.mode) else {
            throw "Invalid Mode"
        }
        guard ["noPadding", "pkcs7"].contains(cryptoFields.padding) else {
            throw "Invalid Padding"
        }
        return key
    }

    /// 校验 iv 的长度并返回，CBC/GCM 必须传 iv
    private static func iv(for fields: CryptoSettingFields) throws -> String {
        guard ["CBC", "GCM"].contains(fields.mode) else {
            return ""
        }
        let expectIVLength = ["CBC": 16, "GCM": 12][fields.mode] ?? 0
        guard let ivField = fields.iv, ivField.count == expectIVLength else {
            throw String(format: "enterIv".localized, expectIVLength)
        }
        return ivField
    }

    init(cryptoFields: CryptoSettingFields) throws {
        let key = try AESCryptoModel.validate(cryptoFields: cryptoFields)
        let iv = try AESCryptoModel.iv(for: cryptoFields)

        let mode: BlockMode
        switch cryptoFields.mode {
        case "CBC":
            mode = CBC(iv: iv.bytes)
        case "ECB":
            mode = ECB()
        case "GCM":
            mode = GCM(iv: iv.bytes, mode: .combined)
        default:
            throw "Invalid Mode"
        }

        let padding: Padding
        switch cryptoFields.padding {
        case "noPadding":
            padding = .noPadding
        case "pkcs7":
            padding = .pkcs7
        default:
            throw "Invalid Padding"
        }

        self.key = key
        self.mode = mode
        self.padding = padding
        self.aes = try AES(key: key.bytes, blockMode: self.mode, padding: self.padding)
    }

    func encrypt(text: String) throws -> String {
        return try aes.encrypt(Array(text.utf8)).toBase64()
    }

    func decrypt(ciphertext: String) throws -> String {
        return try String(data: Data(aes.decrypt(Array(base64: ciphertext))), encoding: .utf8) ?? ""
    }
}
