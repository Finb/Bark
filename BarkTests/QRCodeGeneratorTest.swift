//
//  QRCodeGeneratorTest.swift
//  BarkTests
//
//  Created by xic on 2026/10/16.
//  Copyright © 2026 Fin. All rights reserved.
//
@testable import Bark
import Testing

struct QRCodeGeneratorTest {
    @Test("推送 URL 能生成指定尺寸的二维码")
    func pushURL() {
        let image = QRCodeGenerator.image(for: "https://api.day.app/exampleDeviceKey", size: 512)
        #expect(image != nil)
        #expect(abs((image?.size.width ?? 0) - 512) < 1)
        #expect(abs((image?.size.height ?? 0) - 512) < 1)
    }

    @Test("仅 Key 也能生成二维码")
    func keyOnly() {
        #expect(QRCodeGenerator.image(for: "exampleDeviceKey", size: 256) != nil)
    }

    @Test("空字符串返回 nil")
    func emptyString() {
        #expect(QRCodeGenerator.image(for: "", size: 512) == nil)
    }
}
