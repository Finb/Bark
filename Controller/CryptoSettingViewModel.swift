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
        let algorithmList: Driver<[Algorithm]>
        let modeList: Driver<[String]>
        let paddingList: Driver<[String]>
        let keyLenght: Driver<Int>
        var showSnackbar: Driver<String>
    }

    struct Dependencies {
        let settingFieldRelay: BehaviorRelay<CryptoSettingFields?>
    }

    private let dependencies: Dependencies

    init(dependencies: Dependencies =
        Dependencies(
            settingFieldRelay: CryptoSettingRelay.shared.fields
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

        let keyLenght = input
            .algorithmChanged
            .compactMap { Algorithm(rawValue: $0) }
            .map { $0.keyLenght }

        // 保存配置
        input.done
            .filter { fields in
                do {
                    _ = try AESCryptoModel(cryptoFields: fields)
                    return true
                }
                catch {
                    showSnackbar.accept(error.rawString())
                    return false
                }
            }.drive(onNext: { [weak self] fields in
                // 保存设置
                self?.dependencies.settingFieldRelay.accept(fields)
            }).disposed(by: rx.disposeBag)

        return Output(
            algorithmList: Driver.just([Algorithm.aes128, Algorithm.aes192, Algorithm.aes256]),
            modeList: Driver.merge(Driver.just(["CBC", "ECB", "GCM"]), modeList),
            paddingList: Driver.just(["pkcs7"]),
            keyLenght: Driver.merge(Driver.just(16), keyLenght),
            showSnackbar: showSnackbar.asDriver(onErrorDriveWith: .empty())
        )
    }

}
