//
//  EncryptedPushParamsTests.swift
//  BarkTests
//
//  Copyright © 2026 Fin. All rights reserved.
//

@testable import Bark
import Foundation
import Testing
import XCTest

struct EncryptedPushParamsTests {
    private let key = "0123456789abcdef0123456789abcdef"

    private func fields(algorithm: String = "AES256", mode: String, padding: String, key: String?, iv: String?) -> CryptoSettingFields {
        CryptoSettingFields(algorithm: algorithm, mode: mode, padding: padding, key: key, iv: iv)
    }

    private var gcmFields: CryptoSettingFields {
        fields(mode: "GCM", padding: "noPadding", key: key, iv: nil)
    }

    /// 用返回的 iv 解密 ciphertext，还原出 JSON 对象
    private func decrypt(result: [String: Any], key: String? = nil, algorithm: String = "AES256") throws -> [String: Any] {
        let key = key ?? self.key
        let ciphertext = try #require(result["ciphertext"] as? String)
        let iv = try #require(result["iv"] as? String)
        let aes = try AESCryptoModel(cryptoFields: fields(algorithm: algorithm, mode: "GCM", padding: "noPadding", key: key, iv: iv))
        let json = try aes.decrypt(ciphertext: ciphertext)
        let data = try #require(json.data(using: .utf8))
        let object = try JSONSerialization.jsonObject(with: data)
        return try #require(object as? [String: Any])
    }

    @Test("加密后可用返回的 iv 解回原始参数")
    func testRoundtrip() throws {
        let params: [String: Any] = [
            "title": "Sample Title",
            "body": "Sample body text",
            "url": "https://example.com/path",
            "badge": 3
        ]

        let result = try EncryptedPushParams.encrypt(params: params, fields: gcmFields)
        let decrypted = try decrypt(result: result)

        #expect(decrypted["title"] as? String == "Sample Title")
        #expect(decrypted["body"] as? String == "Sample body text")
        #expect(decrypted["url"] as? String == "https://example.com/path")
        #expect(decrypted["badge"] as? Int == 3)
        #expect(decrypted.count == params.count)
    }

    @Test("每次加密使用不同的 iv 和密文")
    func testRandomIv() throws {
        let params: [String: Any] = ["body": "Sample body text"]

        let first = try EncryptedPushParams.encrypt(params: params, fields: gcmFields)
        let second = try EncryptedPushParams.encrypt(params: params, fields: gcmFields)

        #expect(first["iv"] != second["iv"])
        #expect(first["ciphertext"] != second["ciphertext"])
    }

    @Test("iv 为 12 位字母数字")
    func testIvFormat() throws {
        let allowed = Set("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")

        for _ in 0 ..< 20 {
            let result = try EncryptedPushParams.encrypt(params: ["body": "Sample body text"], fields: gcmFields)
            let iv = try #require(result["iv"])
            #expect(iv.count == 12)
            #expect(iv.allSatisfy { allowed.contains($0) })
        }
    }

    @Test("非 GCM 模式抛错", arguments: ["CBC", "ECB"])
    func testRejectsNonGCMMode(mode: String) throws {
        // 除模式外都是合法配置，确保拒绝来自模式校验
        let fields = fields(mode: mode, padding: "pkcs7", key: key, iv: mode == "CBC" ? "0123456789abcdef" : nil)

        let error = #expect(throws: (any Error).self) {
            try EncryptedPushParams.encrypt(params: ["body": "Sample body text"], fields: fields)
        }
        #expect(error?.rawString() == "encryptedPushRequiresGCM".localized)
    }

    @Test("key 缺失时抛错")
    func testMissingKey() throws {
        let fields = fields(mode: "GCM", padding: "noPadding", key: nil, iv: nil)

        let error = #expect(throws: (any Error).self) {
            try EncryptedPushParams.encrypt(params: ["body": "Sample body text"], fields: fields)
        }
        #expect(error?.rawString() == "Key is missing")
    }

    @Test("ttl 留在请求参数顶层，不进密文")
    func testRequestParamsKeepsTTLInPlaintext() throws {
        let params: [String: Any] = [
            "body": "Sample body text",
            "ttl": 60
        ]

        let result = try EncryptedPushParams.requestParams(params: params, fields: gcmFields)

        #expect(Set(result.keys) == ["ciphertext", "iv", "ttl"])
        #expect(result["ttl"] as? Int == 60)

        let payload = try decrypt(result: result)
        #expect(!payload.keys.contains("ttl"))
        #expect(payload["body"] as? String == "Sample body text")
        #expect(payload.count == 1)
    }

    @Test("无 ttl 时只返回 ciphertext 和 iv")
    func testRequestParamsWithoutTTL() throws {
        let result = try EncryptedPushParams.requestParams(params: ["body": "Sample body text"], fields: gcmFields)

        #expect(Set(result.keys) == ["ciphertext", "iv"])

        let payload = try decrypt(result: result)
        #expect(payload["body"] as? String == "Sample body text")
        #expect(payload.count == 1)
    }

    @Test("一次性密钥的长度决定 AES 位数", arguments: [(16, "AES128"), (24, "AES192"), (32, "AES256")])
    func testRequestParamsInfersAlgorithm(keyLength: Int, algorithm: String) throws {
        let encryptionKey = String(repeating: "k", count: keyLength)

        let result = try EncryptedPushParams.requestParams(params: ["body": "Sample body text"], encryptionKey: encryptionKey)

        #expect(Set(result.keys) == ["ciphertext", "iv"])

        let payload = try decrypt(result: result, key: encryptionKey, algorithm: algorithm)
        #expect(payload["body"] as? String == "Sample body text")
    }

    @Test("一次性密钥沿用 ttl 明文透传")
    func testRequestParamsWithEncryptionKeyKeepsTTL() throws {
        let params: [String: Any] = ["body": "Sample body text", "ttl": 60]

        let result = try EncryptedPushParams.requestParams(params: params, encryptionKey: key)

        #expect(Set(result.keys) == ["ciphertext", "iv", "ttl"])
        #expect(result["ttl"] as? Int == 60)

        let payload = try decrypt(result: result)
        #expect(!payload.keys.contains("ttl"))
    }

    @Test("一次性密钥长度非法时抛错", arguments: [0, 15, 20, 31, 33])
    func testRejectsInvalidKeyLength(keyLength: Int) throws {
        let error = #expect(throws: (any Error).self) {
            try EncryptedPushParams.requestParams(
                params: ["body": "Sample body text"],
                encryptionKey: String(repeating: "k", count: keyLength)
            )
        }
        #expect(error?.rawString() == "encryptionKeyLengthInvalid".localized)
    }

    /// Shortcuts 用 localizedDescription 展示错误，字符串错误必须原样呈现
    @Test("字符串错误的 localizedDescription 是文案本身")
    func testStringErrorIsReadable() throws {
        #expect(("boom" as any Error).localizedDescription == "boom")

        let error = #expect(throws: (any Error).self) {
            try EncryptedPushParams.requestParams(params: [:], encryptionKey: "tooShort")
        }
        #expect(error?.localizedDescription == "encryptionKeyLengthInvalid".localized)
    }
}

/// 快捷指令的加密套件选项
class PushEncryptionSuiteTests: XCTestCase {
    /// 选项顺序决定快捷指令下拉菜单的展示顺序
    func testCaseOrder() throws {
        guard #available(iOS 16, *) else { return }

        XCTAssertEqual(PushEncryptionSuite.allCases.map(\.rawValue), ["none", "AES-GCM"])
    }

    func testEveryCaseHasDisplayRepresentation() throws {
        guard #available(iOS 16, *) else { return }

        for suite in PushEncryptionSuite.allCases {
            XCTAssertNotNil(PushEncryptionSuite.caseDisplayRepresentations[suite], "\(suite.rawValue) 缺少展示文案")
        }
    }

    func testNoneDisplayNameIsLocalized() {
        XCTAssertNotEqual("encryptionSuiteNone".localized, "encryptionSuiteNone")
    }
}

/// 「发送推送到其他设备」快捷指令选择加密方式后的行为
class PushToOtherIntentEncryptionTests: XCTestCase {
    /// 默认不加密，用户要加密必须显式选择套件
    func testDefaultSuiteIsNone() throws {
        guard #available(iOS 16, *) else { return }

        XCTAssertEqual(PushToOtherIntent().encryptionSuite, PushEncryptionSuite.none)
    }

    /// 选了共享密钥却没填密钥时必须报错，不能静默降级成明文
    func testSharedKeyRequiresEncryptionKey() async throws {
        guard #available(iOS 16, *) else { return }

        for encryptionKey in [nil, ""] as [String?] {
            var intent = PushToOtherIntent()
            intent.address = "https://push.example.com/ExampleKey"
            intent.isCall = false
            intent.isCritical = false
            intent.encryptionSuite = .aesGCM
            intent.encryptionKey = encryptionKey

            do {
                _ = try await intent.perform()
                XCTFail("缺少共享密钥时应抛错，不应发出请求")
            } catch {
                XCTAssertEqual(error.rawString(), "encryptionKeyRequired".localized)
            }
        }
    }

    func testKeyRequiredMessageIsLocalized() {
        XCTAssertNotEqual("encryptionKeyRequired".localized, "encryptionKeyRequired")
    }

    /// 填了密钥却选「不加密」是矛盾配置，静默发明文是最坏的结果，必须报错
    func testPlaintextRejectsEncryptionKey() async throws {
        guard #available(iOS 16, *) else { return }

        var intent = PushToOtherIntent()
        intent.address = "https://push.example.com/ExampleKey"
        intent.isCall = false
        intent.isCritical = false
        intent.encryptionSuite = .none
        intent.encryptionKey = "0123456789abcdef0123456789abcdef"

        do {
            _ = try await intent.perform()
            XCTFail("填了密钥却不加密时应抛错，不应发出明文请求")
        } catch {
            XCTAssertEqual(error.rawString(), "encryptionSuiteRequiredForKey".localized)
        }
    }

    func testSuiteRequiredForKeyMessageIsLocalized() {
        XCTAssertNotEqual("encryptionSuiteRequiredForKey".localized, "encryptionSuiteRequiredForKey")
    }
}
