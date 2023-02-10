//
//  CryptoSettingModel.swift
//  Bark
//
//  Created by huangfeng on 2022/11/10.
//  Copyright © 2022 Fin. All rights reserved.
//

import CryptoSwift
import Foundation
class CryptoSettingModel: ViewModel, ViewModelType {
    struct Input {}

    struct Output {}

    func transform(input: Input) -> Output {
        return Output()
    }

    override init() {
        super.init()

        do {
            let aes = try AES(key: "ABCDEFGHIJKLMNOP", iv: "1234567890123456") // aes128
            let ciphertext = try aes.encrypt(Array("hello,world".utf8))
            print("tttt \(ciphertext.toBase64())")
        } catch {
            print("tttt \(error.rawString())")
        }
    }
}
