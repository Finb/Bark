//
//  CryptoSettingViewModel.swift
//  Bark
//
//  Created by huangfeng on 2022/11/10.
//  Copyright © 2022 Fin. All rights reserved.
//

import CryptoSwift
import Foundation
import RxCocoa
import RxSwift

class CryptoSettingViewModel: ViewModel, ViewModelType {
    struct Input {
        let algorithmChanged: Driver<String>
        let copyScript: Driver<CryptoSettingFields>
        let done: Driver<CryptoSettingFields>
    }

    struct Output {
        let initial: Driver<(algorithmList: [Algorithm], modeList: [String], paddingList: [String], initialFields: CryptoSettingFields?)>
        let modeListChanged: Driver<[String]>
        let paddingListChanged: Driver<[String]>
        let keyLenghtChanged: Driver<Int>
        let showSnackbar: Driver<String>
        let done: Driver<Void>
        let copy: Driver<String>
    }

    struct Dependencies {
        let settingFieldRelay: BehaviorRelay<CryptoSettingFields?>
        let deviceKey: Driver<String>
    }

    private let dependencies: Dependencies

    init(dependencies: Dependencies =
        Dependencies(
            settingFieldRelay: CryptoSettingRelay.shared.fields,
            // Key 好像没有对应的事件流，先“just”，懒得写了
            deviceKey: Driver.just(ServerManager.shared.currentServer.key)
        )
    ) {
        self.dependencies = dependencies
    }

    func transform(input: Input) -> Output {

        let showSnackbar = PublishRelay<String>()

        let modeList = input
            .algorithmChanged
            .compactMap { Algorithm(rawValue: $0) }
            .map { $0.modes }

        let keyLenght =
            Driver.merge([
                Driver.just(dependencies.settingFieldRelay.value)
                    .compactMap { $0 }
                    .compactMap { Algorithm(rawValue: $0.algorithm)?.keyLenght },
                input
                    .algorithmChanged
                    .compactMap { Algorithm(rawValue: $0)?.keyLenght },
            ])

        // 保存配置
        let done = input.done
            .filter { fields in
                do {
                    _ = try AESCryptoModel(cryptoFields: fields)
                    return true
                }
                catch {
                    showSnackbar.accept(error.rawString())
                    return false
                }
            }
        done.drive(onNext: { [weak self] fields in
            // 保存设置
            self?.dependencies.settingFieldRelay.accept(fields)
        }).disposed(by: rx.disposeBag)

        let copyScript = input.copyScript
            .filter { [weak self] fields in
                do {
                    _ = try AESCryptoModel(cryptoFields: fields)
                    // 保存配置
                    self?.dependencies.settingFieldRelay.accept(fields)
                    return true
                }
                catch {
                    showSnackbar.accept(error.rawString())
                    return false
                }
            }
        let copy = Driver.combineLatest(copyScript, dependencies.deviceKey)
            .map { fields, deviceKey in
                return
                    """
                    #!/usr/bin/env bash

                    set -e

                    # bark key
                    deviceKey='\(deviceKey)'
                    # push payload
                    json='{"body": "test"}'

                    # must be 16 bytes long
                    key='\(fields.key ?? "")'
                    iv='\(fields.iv ?? "")'

                    # openssl requires Hex encoding of manual keys and IVs, not ASCII encoding.
                    key=$(printf $key | xxd -ps -c 200)
                    iv=$(printf $iv | xxd -ps -c 200)

                    ciphertext=$(echo -n $json | openssl enc -aes-\(fields.algorithm.suffix(3))-\(fields.mode.lowercased()) -K $key -iv $iv | base64)
                    echo $ciphertext
                    # curl --data-urlencode "ciphertext=$ciphertext" https://api.day.app/$deviceKey
                    """
            }

        return Output(
            initial: Driver.just((
                algorithmList: [Algorithm.aes128, Algorithm.aes192, Algorithm.aes256],
                modeList: ["CBC", "ECB"],
                paddingList: ["okcs7"],
                initialFields: dependencies.settingFieldRelay.value
            )),
            modeListChanged: modeList,
            paddingListChanged: Driver.just(["pkcs7"]),
            keyLenghtChanged: keyLenght,
            showSnackbar: showSnackbar.asDriver(onErrorDriveWith: .empty()),
            done: done.map { _ in () },
            copy: copy
        )
    }
}
