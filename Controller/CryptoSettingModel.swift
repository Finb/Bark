//
//  CryptoSettingModel.swift
//  Bark
//
//  Created by huangfeng on 2022/11/10.
//  Copyright © 2022 Fin. All rights reserved.
//

import CryptoSwift
import Foundation
import RxCocoa
import RxSwift

class CryptoSettingModel: ViewModel, ViewModelType {
    struct Input {
        let algorithmChanged: Driver<String>
    }

    struct Output {
        let algorithmList: Driver<[Algorithm]>
        let modeList: Driver<[String]>
        let paddingList: Driver<[String]>
        let keyLenght: Driver<Int>
    }

    func transform(input: Input) -> Output {
        let modeList = input
            .algorithmChanged
            .compactMap { Algorithm(rawValue: $0) }
            .map { $0.modes }

        let keyLenght = input
            .algorithmChanged
            .compactMap { Algorithm(rawValue: $0) }
            .map { $0.keyLenght }

        return Output(
            algorithmList: Driver.just([Algorithm.aes128, Algorithm.aes192, Algorithm.aes256]),
            modeList: Driver.merge(Driver.just(["CBC", "ECB", "GCM"]), modeList),
            paddingList: Driver.just(["pkcs7"]),
            keyLenght: Driver.merge(Driver.just(16), keyLenght)
        )
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
