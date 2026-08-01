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
    /// 表单的一次完整取值，页面初次加载和清除配置后都用它铺满控件
    typealias FormState = (algorithmList: [Algorithm], modeList: [String], paddingList: [String], fields: CryptoSettingFields)

    struct Input {
        let algorithmChanged: Driver<String>
        let modeChanged: Driver<String>
        let copyScript: Driver<CryptoSettingFields>
        let done: Driver<CryptoSettingFields>
        let clear: Driver<Void>
    }

    struct Output {
        let initial: Driver<FormState>
        let reset: Driver<FormState>
        let modeListChanged: Driver<[String]>
        let paddingListChanged: Driver<[String]>
        let keyLengthChanged: Driver<Int>
        let insecureModeNoticeHidden: Driver<Bool>
        let showSnackbar: Driver<String>
        let done: Driver<Void>
        let copy: Driver<String>
    }

    struct Dependencies {
        let settingFieldRelay: BehaviorRelay<CryptoSettingFields?>
        let deviceKey: Driver<String>
        let serverAddress: Driver<String>
    }

    /// 未保存过配置时的初始选择，GCM 是三种模式里唯一没有已知风险的
    private static let defaultFields = CryptoSettingFields(
        algorithm: Algorithm.aes128.rawValue,
        mode: "GCM",
        padding: "noPadding",
        key: nil,
        iv: nil
    )

    private static func paddingList(for mode: String) -> [String] {
        mode == "GCM" ? ["noPadding"] : ["pkcs7"]
    }

    private static func formState(for fields: CryptoSettingFields) -> FormState {
        (
            algorithmList: [Algorithm.aes128, Algorithm.aes192, Algorithm.aes256],
            modeList: ["GCM", "CBC", "ECB"],
            paddingList: paddingList(for: fields.mode),
            fields: fields
        )
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
        let initialFields = dependencies.settingFieldRelay.value ?? Self.defaultFields

        let modeList = input
            .algorithmChanged
            .compactMap { Algorithm(rawValue: $0) }
            .map { $0.modes }

        let paddingList = input
            .modeChanged
            .map { Self.paddingList(for: $0) }

        let keyLength =
            Driver.merge([
                Driver.just(initialFields)
                    .compactMap { Algorithm(rawValue: $0.algorithm)?.keyLength },
                input
                    .algorithmChanged
                    .compactMap { Algorithm(rawValue: $0)?.keyLength }
            ])

        let insecureModeNoticeHidden =
            Driver.merge([
                Driver.just(initialFields.mode),
                input.modeChanged
            ])
            .map { $0 == "GCM" }

        // 保存配置
        let done = input.done
            .filter { fields in
                do {
                    try fields.validate()
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

        // 清除配置，表单回到默认态
        let reset = input.clear.map { Self.formState(for: Self.defaultFields) }
        input.clear.drive(onNext: { [weak self] in
            self?.dependencies.settingFieldRelay.accept(nil)
        }).disposed(by: rx.disposeBag)

        let copyScript = input.copyScript
            .filter { [weak self] fields in
                do {
                    try fields.validate()
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
                let key = fields.key ?? ""
                let ivLength = fields.expectedIvLength ?? 0
                let usesIv = fields.expectedIvLength != nil
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
                        const iv = crypto.randomBytes(6).toString('hex');

                        // AES-\(fields.algorithm.suffix(3))-GCM
                        const cipher = crypto.createCipheriv('aes-\(fields.algorithm.suffix(3))-gcm', Buffer.from(key, 'utf8'), Buffer.from(iv, 'utf8'));
                        const encrypted = Buffer.concat([
                          cipher.update(json, 'utf8'),
                          cipher.final()
                        ]);
                        const tag = cipher.getAuthTag()
                        
                        const combined = Buffer.concat([encrypted, tag])
                        let ciphertext = combined.toString('base64')

                        console.log(ciphertext);

                        // \("ciphertextComment".localized)
                        const pushUrl = `\(serverAddress)/${deviceKey}?ciphertext=${encodeURIComponent(ciphertext)}&iv=${encodeURIComponent(iv)}`;
                        """
                } else {
                    // ECB 不使用 iv，相关片段整段省略，避免留下空行
                    let ivSetup = usesIv ? "\n# \("ivComment".localized)\niv=$(openssl rand -hex \(ivLength / 2))" : ""
                    let ivHexSetup = usesIv ? "\nivHex=$(printf $iv | xxd -ps -c 200)" : ""
                    let ivEncryptArgument = usesIv ? "-iv $ivHex " : ""
                    let ivCurlArgument = usesIv ? " --data-urlencode \"iv=$iv\"" : ""

                    return
                        """
                        #!/usr/bin/env bash

                        # Documentation: \("encryptionUrl".localized)

                        set -e

                        # bark key
                        deviceKey='\(deviceKey)'
                        # push payload
                        json='{"body": "test", "sound": "birdsong"}'

                        # \("keyComment".localized(with: Int(fields.algorithm.suffix(3))! / 8))
                        key='\(key)'\(ivSetup)

                        # \("opensslEncodingComment".localized)
                        key=$(printf $key | xxd -ps -c 200)\(ivHexSetup)

                        # \("base64Notice".localized)
                        ciphertext=$(echo -n $json | openssl enc -aes-\(fields.algorithm.suffix(3))-\(fields.mode.lowercased()) -K $key \(ivEncryptArgument)| base64)

                        echo $ciphertext

                        # \("ciphertextComment".localized)
                        curl --data-urlencode "ciphertext=$ciphertext"\(ivCurlArgument) \(serverAddress)/$deviceKey
                        """
                }
            }

        return Output(
            initial: Driver.just(Self.formState(for: initialFields)),
            reset: reset,
            modeListChanged: modeList,
            paddingListChanged: paddingList,
            keyLengthChanged: keyLength,
            insecureModeNoticeHidden: insecureModeNoticeHidden,
            showSnackbar: showSnackbar.asDriver(onErrorDriveWith: .empty()),
            done: done.map { _ in () },
            copy: copy
        )
    }
}
