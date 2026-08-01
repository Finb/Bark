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
            XCTAssertEqual(val.fields.mode, "GCM")
            XCTAssertEqual(val.fields.padding, "noPadding")
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
            XCTAssertEqual(val.fields.algorithm, "AES192")
            XCTAssertEqual(val.fields.mode, "CBC")
            XCTAssertEqual(val.fields.padding, "pkcs7")
            XCTAssertEqual(val.fields.key, "0123456789abcdef01234567")
            XCTAssertEqual(val.fields.iv, "0123456789abcdef")
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
            XCTAssertEqual(val.fields.padding, "noPadding")
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

    /// iv 留空不警示，带存量 iv 打开页面则警示，两种状态都要能完成布局
    func testControllerLaysOutInBothIvWarningStates() {
        let cases: [(CryptoSettingFields?, Bool)] = [
            (gcmFields(iv: nil), true),
            (gcmFields(iv: "0123456789ab"), false)
        ]

        for (savedFields, expectsHidden) in cases {
            let controller = CryptoSettingController(viewModel: makeViewModel(savedFields: savedFields))
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
            window.rootViewController = controller
            window.makeKeyAndVisible()
            controller.view.layoutIfNeeded()

            XCTAssertEqual(controller.ivHardcodedWarningLabel.isHidden, expectsHidden)
            XCTAssertEqual(controller.ivTextField.placeholder, "ivOptionalPlaceholder".localized)

            // 清除按钮接在复制按钮下方，且是 scrollView 内容高度的末端
            XCTAssertFalse(controller.clearButton.frame.isEmpty)
            XCTAssertGreaterThanOrEqual(controller.clearButton.frame.minY, controller.copyButton.frame.maxY)
            XCTAssertGreaterThanOrEqual(
                controller.scrollView.contentSize.height,
                controller.clearButton.frame.maxY
            )
        }
    }

    /// iv 留空的配置可以保存
    func testSavesConfigWithEmptyIV() {
        for fields in [gcmFields(iv: nil), cbcFields(iv: nil)] {
            let exp = expectation(description: "\(#function)-\(fields.mode)")
            let relay = BehaviorRelay<CryptoSettingFields?>(value: nil)
            let viewModel = makeViewModel(relay: relay)

            let output = viewModel.transform(input: generateInput(done: Driver.just(fields)))

            output.done.drive(onNext: {
                exp.fulfill()
            }).disposed(by: rx.disposeBag)

            waitForExpectations(timeout: 1, handler: nil)
            XCTAssertEqual(relay.value?.mode, fields.mode)
            XCTAssertNil(relay.value?.iv)
        }
    }

    /// iv 填了错误长度仍然拒绝保存
    func testRejectsConfigWithWrongIVLength() {
        let exp = expectation(description: #function)
        let relay = BehaviorRelay<CryptoSettingFields?>(value: nil)
        let viewModel = makeViewModel(relay: relay)

        // showSnackbar 不重放，输入必须在订阅之后才发出
        let doneTap = PublishRelay<CryptoSettingFields>()
        let output = viewModel.transform(input: generateInput(done: doneTap.asDriver(onErrorDriveWith: .empty())))

        output.showSnackbar.drive(onNext: { message in
            XCTAssertEqual(message, String(format: "enterIv".localized, 12))
            exp.fulfill()
        }).disposed(by: rx.disposeBag)

        doneTap.accept(gcmFields(iv: "wrongLengthIv"))

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertNil(relay.value, "校验失败不应保存")
    }

    /// 清除后配置被删除，表单回到默认态
    func testClearRemovesSavedConfigAndResetsForm() {
        let exp = expectation(description: #function)
        let relay = BehaviorRelay<CryptoSettingFields?>(value: cbcFields(iv: "0123456789abcdef"))
        let viewModel = makeViewModel(relay: relay)

        let clearTap = PublishRelay<Void>()
        let output = viewModel.transform(input: generateInput(clear: clearTap.asDriver(onErrorDriveWith: .empty())))

        output.reset.drive(onNext: { state in
            XCTAssertEqual(state.fields.mode, "GCM")
            XCTAssertEqual(state.fields.padding, "noPadding")
            XCTAssertNil(state.fields.key)
            XCTAssertNil(state.fields.iv)
            XCTAssertEqual(state.paddingList, ["noPadding"])
            exp.fulfill()
        }).disposed(by: rx.disposeBag)

        clearTap.accept(())

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertNil(relay.value, "清除后不应残留配置")
    }

    /// 没点清除就不该动已保存的配置
    func testConfigSurvivesWithoutClear() {
        let saved = cbcFields(iv: "0123456789abcdef")
        let relay = BehaviorRelay<CryptoSettingFields?>(value: saved)
        let viewModel = makeViewModel(relay: relay)

        _ = viewModel.transform(input: generateInput())

        XCTAssertEqual(relay.value?.mode, "CBC")
    }

    // 存量 iv 用 key 里不会出现的字符，避免 contains 断言误判
    private let storedGcmIv = "zzzzzzzzzzzz"
    private let storedCbcIv = "zzzzzzzzzzzzzzzz"

    /// GCM 示例脚本每次运行自行随机生成 iv
    func testGCMScriptGeneratesRandomIV() {
        copiedScript(for: gcmFields(iv: storedGcmIv)) { script in
            XCTAssertTrue(script.contains("crypto.randomBytes(6).toString('hex')"), script)
            XCTAssertFalse(script.contains(self.storedGcmIv), "存量 iv 不应出现在脚本里")
            XCTAssertFalse(script.contains("consoleComment".localized), "预计算密文注释应已删除")
        }
    }

    /// CBC 示例脚本自行随机生成 iv，并把原始 iv 传给服务端
    func testCBCScriptGeneratesRandomIV() {
        copiedScript(for: cbcFields(iv: storedCbcIv)) { script in
            XCTAssertTrue(script.contains("openssl rand -hex 8"), script)
            XCTAssertTrue(script.contains("--data-urlencode \"iv=$iv\""), script)
            XCTAssertFalse(script.contains(self.storedCbcIv), "存量 iv 不应出现在脚本里")
            XCTAssertFalse(script.contains("consoleComment".localized), "预计算密文注释应已删除")
        }
    }

    /// ECB 不使用 iv，脚本里不该出现任何 iv 相关内容
    func testECBScriptHasNoIV() {
        let fields = CryptoSettingFields(algorithm: "AES256", mode: "ECB", padding: "pkcs7", key: key256, iv: nil)
        copiedScript(for: fields) { script in
            XCTAssertFalse(script.contains("openssl rand"), script)
            XCTAssertFalse(script.contains("-iv"), script)
            XCTAssertFalse(script.contains("iv="), script)
            XCTAssertFalse(script.contains("consoleComment".localized), "预计算密文注释应已删除")
            XCTAssertFalse(script.contains("\n\n\n"), "省掉 iv 的地方不应留下连续空行:\n\(script)")
        }
    }

    private let key256 = "0123456789abcdef0123456789abcdef"

    private func gcmFields(iv: String?) -> CryptoSettingFields {
        CryptoSettingFields(algorithm: "AES256", mode: "GCM", padding: "noPadding", key: key256, iv: iv)
    }

    private func cbcFields(iv: String?) -> CryptoSettingFields {
        CryptoSettingFields(algorithm: "AES256", mode: "CBC", padding: "pkcs7", key: key256, iv: iv)
    }

    /// 触发一次复制脚本，把生成的脚本交给断言
    private func copiedScript(for fields: CryptoSettingFields, assert: @escaping (String) -> Void) {
        let exp = expectation(description: "\(#function)-\(fields.mode)")
        let viewModel = makeViewModel(relay: BehaviorRelay<CryptoSettingFields?>(value: nil))

        let output = viewModel.transform(input: generateInput(copyScript: Driver.just(fields)))

        output.copy.drive(onNext: { script in
            assert(script)
            exp.fulfill()
        }).disposed(by: rx.disposeBag)

        waitForExpectations(timeout: 1, handler: nil)
    }

    private func makeViewModel(savedFields: CryptoSettingFields?) -> CryptoSettingViewModel {
        makeViewModel(relay: BehaviorRelay<CryptoSettingFields?>(value: savedFields))
    }

    private func makeViewModel(relay: BehaviorRelay<CryptoSettingFields?>) -> CryptoSettingViewModel {
        CryptoSettingViewModel(dependencies: CryptoSettingViewModel.Dependencies(
            settingFieldRelay: relay,
            deviceKey: Driver.just("testDeviceKey"),
            serverAddress: Driver.just("https://example.com")
        ))
    }

    private func generateInput(
        algorithmChanged: Driver<String> = Driver.empty(),
        modeChanged: Driver<String> = Driver.empty(),
        copyScript: Driver<CryptoSettingFields> = Driver.empty(),
        done: Driver<CryptoSettingFields> = Driver.empty(),
        clear: Driver<Void> = Driver.empty()
    ) -> CryptoSettingViewModel.Input {
        CryptoSettingViewModel.Input(
            algorithmChanged: algorithmChanged,
            modeChanged: modeChanged,
            copyScript: copyScript,
            done: done,
            clear: clear
        )
    }
}
