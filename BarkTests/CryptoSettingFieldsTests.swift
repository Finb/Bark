//
//  CryptoSettingFieldsTests.swift
//  BarkTests
//
//  Copyright © 2026 Fin. All rights reserved.
//

@testable import Bark
import Testing

struct CryptoSettingFieldsTests {
    private let key128 = "0123456789abcdef"
    private let key256 = "0123456789abcdef0123456789abcdef"

    private func fields(algorithm: String, mode: String, padding: String, key: String?, iv: String?) -> CryptoSettingFields {
        CryptoSettingFields(algorithm: algorithm, mode: mode, padding: padding, key: key, iv: iv)
    }

    @Test("iv 留空的配置可以通过校验", arguments: [
        ("GCM", "noPadding"),
        ("CBC", "pkcs7"),
        ("ECB", "pkcs7")
    ])
    func testValidateAcceptsEmptyIv(mode: String, padding: String) throws {
        try fields(algorithm: "AES256", mode: mode, padding: padding, key: key256, iv: nil).validate()
        try fields(algorithm: "AES256", mode: mode, padding: padding, key: key256, iv: "").validate()
    }

    @Test("iv 填了正确长度可以通过校验", arguments: [
        ("GCM", "noPadding", "0123456789ab"),
        ("CBC", "pkcs7", "0123456789abcdef")
    ])
    func testValidateAcceptsCorrectIvLength(mode: String, padding: String, iv: String) throws {
        try fields(algorithm: "AES256", mode: mode, padding: padding, key: key256, iv: iv).validate()
    }

    @Test("iv 填了错误长度仍被拒绝", arguments: [
        ("GCM", 12, "0123456789abcdef"),
        ("CBC", 16, "0123456789ab")
    ])
    func testValidateRejectsWrongIvLength(mode: String, expectedLength: Int, iv: String) throws {
        let fields = fields(algorithm: "AES256", mode: mode, padding: "noPadding", key: key256, iv: iv)

        let error = #expect(throws: (any Error).self) {
            try fields.validate()
        }
        #expect(error?.rawString() == String(format: "enterIv".localized, expectedLength))
    }

    @Test("key 长度不符仍被拒绝")
    func testValidateRejectsWrongKeyLength() throws {
        let fields = fields(algorithm: "AES256", mode: "GCM", padding: "noPadding", key: key128, iv: nil)

        let error = #expect(throws: (any Error).self) {
            try fields.validate()
        }
        #expect(error?.rawString() == String(format: "enterKey".localized, 32))
    }

    @Test("key 缺失仍被拒绝")
    func testValidateRejectsMissingKey() throws {
        let fields = fields(algorithm: "AES256", mode: "GCM", padding: "noPadding", key: nil, iv: nil)

        let error = #expect(throws: (any Error).self) {
            try fields.validate()
        }
        #expect(error?.rawString() == "Key is missing")
    }

    /// 解密时必须有可用的 iv，校验放宽不能影响这里
    @Test("CBC / GCM 缺少 iv 时无法构造 AESCryptoModel", arguments: [
        ("GCM", "noPadding", 12),
        ("CBC", "pkcs7", 16)
    ])
    func testCryptoModelStillRequiresIv(mode: String, padding: String, expectedLength: Int) throws {
        let fields = fields(algorithm: "AES256", mode: mode, padding: padding, key: key256, iv: nil)

        let error = #expect(throws: (any Error).self) {
            try AESCryptoModel(cryptoFields: fields)
        }
        #expect(error?.rawString() == String(format: "enterIv".localized, expectedLength))
    }

    @Test("ECB 不需要 iv 即可构造 AESCryptoModel")
    func testCryptoModelAllowsMissingIvForECB() throws {
        _ = try AESCryptoModel(cryptoFields: fields(algorithm: "AES256", mode: "ECB", padding: "pkcs7", key: key256, iv: nil))
    }

    @Test("iv 长度期望值")
    func testExpectedIvLength() {
        #expect(fields(algorithm: "AES256", mode: "GCM", padding: "noPadding", key: key256, iv: nil).expectedIvLength == 12)
        #expect(fields(algorithm: "AES256", mode: "CBC", padding: "pkcs7", key: key256, iv: nil).expectedIvLength == 16)
        #expect(fields(algorithm: "AES256", mode: "ECB", padding: "pkcs7", key: key256, iv: nil).expectedIvLength == nil)
    }
}
