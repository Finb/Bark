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
            // GCM 排在首位，它是唯一没有已知风险的模式
            return ["GCM", "CBC", "ECB"]
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

extension CryptoSettingFields {
    /// CBC / GCM 需要 iv 且长度固定，ECB 不使用 iv
    var expectedIvLength: Int? {
        ["CBC": 16, "GCM": 12][mode]
    }

    /// 校验算法与 key，返回加解密需要的两者
    func validatedAlgorithmAndKey() throws -> (algorithm: Algorithm, key: String) {
        guard let algorithm = Algorithm(rawValue: self.algorithm) else {
            throw "Invalid algorithm"
        }
        guard let key else {
            throw "Key is missing"
        }
        guard algorithm.keyLength == key.count else {
            throw String(format: "enterKey".localized, algorithm.keyLength)
        }
        return (algorithm, key)
    }

    /// 校验设置页填写的配置。iv 允许留空（由发送方每次随机生成），填了则必须符合长度。
    func validate() throws {
        _ = try validatedAlgorithmAndKey()

        guard let iv, !iv.isEmpty, let expectedIvLength else {
            return
        }
        guard iv.count == expectedIvLength else {
            throw String(format: "enterIv".localized, expectedIvLength)
        }
    }
}

struct AESCryptoModel {
    let key: String
    let mode: BlockMode
    let padding: Padding
    let aes: AES
    init(cryptoFields: CryptoSettingFields) throws {
        let key = try cryptoFields.validatedAlgorithmAndKey().key

        // 加解密必须拿到可用的 iv，配置里留空的话由调用方先填入
        var iv = ""
        if let expectedIvLength = cryptoFields.expectedIvLength {
            guard let ivField = cryptoFields.iv, ivField.count == expectedIvLength else {
                throw String(format: "enterIv".localized, expectedIvLength)
            }
            iv = ivField
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
