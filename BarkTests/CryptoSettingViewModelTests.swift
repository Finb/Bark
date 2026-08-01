//
//  CryptoSettingViewModelTests.swift
//  BarkTests
//
//  Copyright © 2026 Fin. All rights reserved.
//

@testable import Bark
import RxCocoa
import RxSwift
import XCTest

class CryptoSettingViewModelTests: XCTestCase {
    /// 未保存过配置时，初始应落在 GCM 上
    func testInitialDefaultsToGCM() {
        let exp = expectation(description: #function)
        let viewModel = makeViewModel(savedFields: nil)

        let output = viewModel.transform(input: generateInput())

        output.initial.drive(onNext: { val in
            XCTAssertEqual(val.initialFields.mode, "GCM")
            XCTAssertEqual(val.initialFields.padding, "noPadding")
            XCTAssertEqual(val.paddingList, ["noPadding"])
            XCTAssertEqual(val.modeList, ["GCM", "CBC", "ECB"])
            exp.fulfill()
        }).disposed(by: rx.disposeBag)

        waitForExpectations(timeout: 1, handler: nil)
    }

    /// 已保存的配置原样透传，padding 列表与之自洽
    func testInitialPassesThroughSavedFields() {
        let exp = expectation(description: #function)
        let saved = CryptoSettingFields(
            algorithm: "AES192",
            mode: "CBC",
            padding: "pkcs7",
            key: "0123456789abcdef01234567",
            iv: "0123456789abcdef"
        )
        let viewModel = makeViewModel(savedFields: saved)

        let output = viewModel.transform(input: generateInput())

        output.initial.drive(onNext: { val in
            XCTAssertEqual(val.initialFields.algorithm, "AES192")
            XCTAssertEqual(val.initialFields.mode, "CBC")
            XCTAssertEqual(val.initialFields.padding, "pkcs7")
            XCTAssertEqual(val.initialFields.key, "0123456789abcdef01234567")
            XCTAssertEqual(val.initialFields.iv, "0123456789abcdef")
            XCTAssertEqual(val.paddingList, ["pkcs7"])
            exp.fulfill()
        }).disposed(by: rx.disposeBag)

        waitForExpectations(timeout: 1, handler: nil)
    }

    /// 已保存 GCM 配置时，padding 列表应是 noPadding 而不是 pkcs7
    func testInitialPaddingListMatchesSavedGCMMode() {
        let exp = expectation(description: #function)
        let saved = CryptoSettingFields(
            algorithm: "AES256",
            mode: "GCM",
            padding: "noPadding",
            key: "0123456789abcdef0123456789abcdef",
            iv: "0123456789ab"
        )
        let viewModel = makeViewModel(savedFields: saved)

        let output = viewModel.transform(input: generateInput())

        output.initial.drive(onNext: { val in
            XCTAssertEqual(val.paddingList, ["noPadding"])
            XCTAssertEqual(val.initialFields.padding, "noPadding")
            exp.fulfill()
        }).disposed(by: rx.disposeBag)

        waitForExpectations(timeout: 1, handler: nil)
    }

    /// 默认的 GCM 不该显示风险提示
    func testInsecureModeNoticeHiddenForInitialGCM() {
        let exp = expectation(description: #function)
        let viewModel = makeViewModel(savedFields: nil)

        let output = viewModel.transform(input: generateInput())

        output.insecureModeNoticeHidden.drive(onNext: { hidden in
            XCTAssertTrue(hidden)
            exp.fulfill()
        }).disposed(by: rx.disposeBag)

        waitForExpectations(timeout: 1, handler: nil)
    }

    /// 切到 CBC / ECB 时显示风险提示
    func testInsecureModeNoticeShownForCBCAndECB() {
        for mode in ["CBC", "ECB"] {
            let exp = expectation(description: "\(#function)-\(mode)")
            let viewModel = makeViewModel(savedFields: nil)

            let output = viewModel.transform(input: generateInput(modeChanged: Driver.just(mode)))

            var hiddenStates: [Bool] = []
            output.insecureModeNoticeHidden.drive(onNext: { hidden in
                hiddenStates.append(hidden)
                if hiddenStates.count == 2 {
                    exp.fulfill()
                }
            }).disposed(by: rx.disposeBag)

            waitForExpectations(timeout: 1, handler: nil)
            XCTAssertEqual(hiddenStates, [true, false], "\(mode) 应从默认 GCM 的隐藏切换为显示")
        }
    }

    /// 提示显示与隐藏两种状态下，页面都要能完成布局
    func testControllerLaysOutInBothNoticeStates() {
        let cbcFields = CryptoSettingFields(
            algorithm: "AES128",
            mode: "CBC",
            padding: "pkcs7",
            key: "0123456789abcdef",
            iv: "0123456789abcdef"
        )

        for (savedFields, expectsHidden) in [(nil, true), (cbcFields, false)] as [(CryptoSettingFields?, Bool)] {
            let controller = CryptoSettingController(viewModel: makeViewModel(savedFields: savedFields))
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
            window.rootViewController = controller
            window.makeKeyAndVisible()
            controller.view.layoutIfNeeded()

            XCTAssertEqual(controller.insecureModeNoticeLabel.isHidden, expectsHidden)
            XCTAssertFalse(controller.insecureModeNoticeLabel.frame.isEmpty, "提示标签应有实际尺寸")
        }
    }

    private func makeViewModel(savedFields: CryptoSettingFields?) -> CryptoSettingViewModel {
        CryptoSettingViewModel(dependencies: CryptoSettingViewModel.Dependencies(
            settingFieldRelay: BehaviorRelay<CryptoSettingFields?>(value: savedFields),
            deviceKey: Driver.just("testDeviceKey"),
            serverAddress: Driver.just("https://example.com")
        ))
    }

    private func generateInput(
        algorithmChanged: Driver<String> = Driver.empty(),
        modeChanged: Driver<String> = Driver.empty(),
        copyScript: Driver<CryptoSettingFields> = Driver.empty(),
        done: Driver<CryptoSettingFields> = Driver.empty()
    ) -> CryptoSettingViewModel.Input {
        CryptoSettingViewModel.Input(
            algorithmChanged: algorithmChanged,
            modeChanged: modeChanged,
            copyScript: copyScript,
            done: done
        )
    }
}
