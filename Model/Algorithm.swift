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

        var keyBytes: [UInt8] = []
        if algorithm.keyLength == key.count {
            keyBytes = Array(key.utf8)
        } else if algorithm.keyLength * 2 == key.count, let decoded = key.hexWithOptions() {
            keyBytes = decoded
        } else {
            throw String(format: "enterKey".localized, algorithm.keyLength)
        }

        var iv: [UInt8] = []
        if ["CBC", "GCM"].contains(cryptoFields.mode) {
            let expectIVLength = [
                "CBC": 16,
                "GCM": 12
            ][cryptoFields.mode] ?? 0

            if let ivField = cryptoFields.iv {
                if ivField.count == expectIVLength {
                    iv = Array(ivField.utf8)
                } else if ivField.count == expectIVLength * 2, let decoded = ivField.hexWithOptions() {
                    iv = decoded
                } else {
                    throw String(format: "enterIv".localized, expectIVLength)
                }
            } else {
                throw String(format: "enterIv".localized, expectIVLength)
            }
        }

        let mode: BlockMode
        switch cryptoFields.mode {
        case "CBC":
            mode = CBC(iv: iv)
        case "ECB":
            mode = ECB()
        case "GCM":
            mode = GCM(iv: iv, mode: .combined)
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
        self.aes = try AES(key: keyBytes, blockMode: self.mode, padding: self.padding)
    }

    func encrypt(text: String) throws -> String {
        return try aes.encrypt(Array(text.utf8)).toBase64()
    }

    func decrypt(ciphertext: String) throws -> String {
        return try String(data: Data(aes.decrypt(Array(base64: ciphertext))), encoding: .utf8) ?? ""
    }
}

private extension String {
    func hexWithOptions() -> [UInt8]? {
        let length = self.count
        if length % 2 != 0 { return nil }
        
        var bytes = [UInt8]()
        bytes.reserveCapacity(length / 2)
        
        var index = self.startIndex
        while index < self.endIndex {
            let nextIndex = self.index(index, offsetBy: 2)
            if let b = UInt8(self[index..<nextIndex], radix: 16) {
                bytes.append(b)
            } else {
                return nil
            }
            index = nextIndex
        }
        return bytes
    }
}
