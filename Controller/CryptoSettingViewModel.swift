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

private func randomIv(mode: String) -> String {
    let length = ["CBC": 16, "GCM": 12][mode] ?? 0
    guard length > 0 else {
        return ""
    }
    let chars = Array("0123456789abcdef")
    return String((0..<length).map { _ in chars.randomElement()! })
}

class CryptoSettingViewModel: ViewModel, ViewModelType {
    struct Input {
        let algorithmChanged: Driver<String>
        let modeChanged: Driver<String>
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

        let paddingList = input
            .modeChanged
            .map { mode in
                if mode == "GCM" {
                    return ["noPadding"]
                } else {
                    return ["pkcs7"]
                }
            }

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
                    try AESCryptoModel.validate(cryptoFields: fields)
                    return true
                } catch {
                    showSnackbar.accept(error.rawString())
                    return false
                }
            }
        done.drive(onNext: { [weak self] fields in
            // 保存设置
            self?.dependencies.settingFieldRelay.accept(self?.preservingIv(fields))
        }).disposed(by: rx.disposeBag)

        let copyScript = input.copyScript
            .filter { [weak self] fields in
                do {
                    try AESCryptoModel.validate(cryptoFields: fields)
                    // 保存配置
                    self?.dependencies.settingFieldRelay.accept(self?.preservingIv(fields))
                    return true
                } catch {
                    showSnackbar.accept(error.rawString())
                    return false
                }
            }
        let copy = Driver.combineLatest(copyScript, dependencies.deviceKey, dependencies.serverAddress)
            .compactMap { fields, deviceKey, serverAddress -> String? in
                let key = fields.key ?? ""
                let iv = randomIv(mode: fields.mode)
                var previewFields = fields
                previewFields.iv = iv
                if fields.mode == "GCM" {
                    return
                        """
                        // Documentation: \("encryptionUrl".localized)
                        
                        const crypto = require('crypto');


                        // bark key
                        const deviceKey = '\(deviceKey)';
                        // push payload
                        const json = JSON.stringify({ body: "test", sound: "birdsong" });

                        // \("keyComment".localized(with: Int(fields.algorithm.suffix(3))! / 8))
                        const key = '\(key)';
                        // \("ivComment".localized)
                        const iv = '\(iv)';

                        // AES-\(fields.algorithm.suffix(3))-GCM
                        const cipher = crypto.createCipheriv('aes-\(fields.algorithm.suffix(3))-gcm', Buffer.from(key, 'utf8'), Buffer.from(iv, 'utf8'));
                        const encrypted = Buffer.concat([
                          cipher.update(json, 'utf8'),
                          cipher.final()
                        ]);
                        const tag = cipher.getAuthTag()
                        
                        const combined = Buffer.concat([encrypted, tag])
                        let ciphertext = combined.toString('base64')

                        // \("consoleComment".localized) "\((try? AESCryptoModel(cryptoFields: previewFields).encrypt(text: "{\"body\":\"test\",\"sound\":\"birdsong\"}")) ?? "")"
                        console.log(ciphertext);

                        // \("ciphertextComment".localized)
                        const pushUrl = `\(serverAddress)/${deviceKey}?ciphertext=${encodeURIComponent(ciphertext)}&iv=${encodeURIComponent(iv)}`;
                        """
                } else {
                    return
                        """
                        #!/usr/bin/env bash
                        
                        # Documentation: \("encryptionUrl".localized)
                        
                        set -e

                        # bark key
                        deviceKey='\(deviceKey)'
                        # push payload
                        json='{"body": "test", "sound": "birdsong"}'

                        # \("keyComment".localized(with: Int(fields.algorithm.suffix(3))! / 8)) )
                        key='\(key)'
                        # \("ivComment".localized)
                        iv='\(iv)'

                        # \("opensslEncodingComment".localized)
                        key=$(printf $key | xxd -ps -c 200)
                        iv=$(printf $iv | xxd -ps -c 200)
                        
                        # \("base64Notice".localized)
                        ciphertext=$(echo -n $json | openssl enc -aes-\(fields.algorithm.suffix(3))-\(fields.mode.lowercased()) -K $key \(iv.count > 0 ? "-iv $iv " : "")| base64)

                        # \("consoleComment".localized) "\((try? AESCryptoModel(cryptoFields: previewFields).encrypt(text: "{\"body\": \"test\", \"sound\": \"birdsong\"}")) ?? "")"
                        echo $ciphertext
                        
                        # \("ciphertextComment".localized)
                        curl --data-urlencode "ciphertext=$ciphertext"\(iv.count == 0 ? "" : " --data-urlencode \"iv=\(iv)\"") \(serverAddress)/$deviceKey
                        """
                }
            }

        return Output(
            initial: Driver.just((
                algorithmList: [Algorithm.aes128, Algorithm.aes192, Algorithm.aes256],
                modeList: ["CBC", "ECB", "GCM"],
                paddingList: ["pkcs7"],
                initialFields: dependencies.settingFieldRelay.value
            )),
            modeListChanged: modeList,
            paddingListChanged: paddingList,
            keyLengthChanged: keyLength,
            showSnackbar: showSnackbar.asDriver(onErrorDriveWith: .empty()),
            done: done.map { _ in () },
            copy: copy
        )
    }

    /// IV 不再由用户在设置页输入，这里保留老用户已保存的 iv 作为兜底
    /// 仅保留与当前 mode 长度匹配的 iv，避免切换 mode 后 iv 不适用
    private func preservingIv(_ fields: CryptoSettingFields) -> CryptoSettingFields {
        var fields = fields
        guard let iv = dependencies.settingFieldRelay.value?.iv else {
            return fields
        }
        let expect = ["CBC": 16, "GCM": 12][fields.mode] ?? 0
        fields.iv = iv.count == expect ? iv : nil
        return fields
    }
}
