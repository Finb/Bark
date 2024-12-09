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
        let keyLengthChanged: Driver<Int>
        let showSnackbar: Driver<String>
        let done: Driver<Void>
        let copy: Driver<String>
    }

    struct Dependencies {
        let settingFieldRelay: BehaviorRelay<CryptoSettingFields?>
        let deviceKey: Driver<String>
        let serverAddress: Driver<String>
    }

    private let dependencies: Dependencies

    init(dependencies: Dependencies =
        Dependencies(
            settingFieldRelay: CryptoSettingRelay.shared.fields,
            // Key 好像没有对应的事件流，先“just”，懒得写了
            deviceKey: Driver.just(ServerManager.shared.currentServer.key),
            serverAddress: Driver.just(ServerManager.shared.currentServer.address)
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

        let keyLength =
            Driver.merge([
                Driver.just(dependencies.settingFieldRelay.value)
                    .compactMap { $0 }
                    .compactMap { Algorithm(rawValue: $0.algorithm)?.keyLength },
                input
                    .algorithmChanged
                    .compactMap { Algorithm(rawValue: $0)?.keyLength }
            ])

        // 保存配置
        let done = input.done
            .filter { fields in
                do {
                    _ = try AESCryptoModel(cryptoFields: fields)
                    return true
                } catch {
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
                } catch {
                    showSnackbar.accept(error.rawString())
                    return false
                }
            }
        let copy = Driver.combineLatest(copyScript, dependencies.deviceKey, dependencies.serverAddress)
            .compactMap { fields, deviceKey, serverAddress -> String? in
                guard fields.mode != "GCM" else {
                    showSnackbar.accept(NSLocalizedString("gcmNotSupported"))
                    return nil
                }
                let key = fields.key ?? ""
                let iv = fields.iv ?? ""
                return
                    """
                    #!/usr/bin/env bash
                    
                    # Documentation: \(NSLocalizedString("encryptionUrl"))
                    
                    set -e

                    # bark key
                    deviceKey='\(deviceKey)'
                    # push payload
                    json='{"body": "test", "sound": "birdsong"}'

                    # \(String(format: NSLocalizedString("keyComment"), Int(fields.algorithm.suffix(3))! / 8))
                    key='\(key)'
                    # \(NSLocalizedString("ivComment"))
                    iv='\(iv)'

                    # \(NSLocalizedString("opensslEncodingComment"))
                    key=$(printf $key | xxd -ps -c 200)
                    iv=$(printf $iv | xxd -ps -c 200)
                    
                    # \(NSLocalizedString("base64Notice"))
                    ciphertext=$(echo -n $json | openssl enc -aes-\(fields.algorithm.suffix(3))-\(fields.mode.lowercased()) -K $key \(iv.count > 0 ? "-iv $iv " : "")| base64)

                    # \(NSLocalizedString("consoleComment")) "\((try? AESCryptoModel(cryptoFields: fields).encrypt(text: "{\"body\": \"test\", \"sound\": \"birdsong\"}")) ?? "")"
                    echo $ciphertext
                    
                    # \(NSLocalizedString("ciphertextComment"))
                    curl --data-urlencode "ciphertext=$ciphertext"\(iv.count == 0 ? "" : " --data-urlencode \"iv=\(iv)\"") \(serverAddress)/$deviceKey
                    """
            }

        return Output(
            initial: Driver.just((
                algorithmList: [Algorithm.aes128, Algorithm.aes192, Algorithm.aes256],
                modeList: ["CBC", "ECB", "GCM"],
                paddingList: ["pkcs7"],
                initialFields: dependencies.settingFieldRelay.value
            )),
            modeListChanged: modeList,
            paddingListChanged: Driver.just(["pkcs7"]),
            keyLengthChanged: keyLength,
            showSnackbar: showSnackbar.asDriver(onErrorDriveWith: .empty()),
            done: done.map { _ in () },
            copy: copy
        )
    }
}
