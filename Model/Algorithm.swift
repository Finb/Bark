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
    init(cryptoFields: CryptoSettingFields) throws {
        guard let algorithm = Algorithm(rawValue: cryptoFields.algorithm) else {
            throw "Invalid algorithm"
        }
        guard let key = cryptoFields.key else {
            throw "Key is missing"
        }

        guard algorithm.keyLength == key.count else {
            throw String(format: "enterKey".localized, algorithm.keyLength)
        }

        var iv = ""
        if ["CBC", "GCM"].contains(cryptoFields.mode) {
            let expectIVLength = [
                "CBC": 16,
                "GCM": 12
            ][cryptoFields.mode] ?? 0

            if let ivField = cryptoFields.iv, ivField.count == expectIVLength {
                iv = ivField
            } else {
                throw String(format: "enterIv".localized, expectIVLength)
            }
        }

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
