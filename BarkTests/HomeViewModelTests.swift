//
//  HomeViewModelTests.swift
//  BarkTests
//
//  Created by huangfeng on 2021/10/21.
//  Copyright © 2021 Fin. All rights reserved.
//

@testable import Bark
import RxCocoa
import RxSwift
import XCTest

class HomeViewModelTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testNewButtonClick() {
        let exp = expectation(description: #function)
        let homeViewModel = HomeViewModel()

        let input = generateInput(addCustomServerTap: Driver.just(()))
        let output = homeViewModel.transform(input: input)

        output.push.drive { viewModel in
            XCTAssertNotNil(viewModel as? NewServerViewModel)
            exp.fulfill()
        }.disposed(by: rx.disposeBag)

        waitForExpectations(timeout: 1, handler: nil)
    }

    /// 测试 查看所有铃声 按钮点击
    func testSoundsTap() {
        let exp = expectation(description: #function)
        let homeViewModel = HomeViewModel()

        let input = generateInput()
        let output = homeViewModel.transform(input: input)

        // 测试是否能正常收到 push model
        output.push.drive { viewModel in
            XCTAssertTrue(viewModel is SoundsViewModel, "Type Error")
            exp.fulfill()
        }.disposed(by: rx.disposeBag)

        // 发送点击事件
        output.previews.drive { models in
            guard let items = models.first?.items, let testPrevieModel = items.first(where: { model in
                model.previewModel.moreViewModel is SoundsViewModel
            }) else {
                assertionFailure("Empty items")
                return
            }
            if let model = testPrevieModel.previewModel.moreViewModel {
                testPrevieModel.noticeTap.accept(model)
            }
        }.disposed(by: rx.disposeBag)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testCopy() {
        let exp = expectation(description: #function)
        let homeViewModel = HomeViewModel()

        let input = generateInput()
        let output = homeViewModel.transform(input: input)

        let testStr = "hello bark"
        // 测试是否正常 copy
        output.copy.drive { str in
            XCTAssertTrue(str == testStr)
            exp.fulfill()
        }.disposed(by: rx.disposeBag)

        // 发送复制事件
        output.previews.drive { models in
            guard let items = models.first?.items, let testPrevieModel = items.first else {
                assertionFailure("Empty items")
                return
            }
            testPrevieModel.copy.accept(testStr)
        }.disposed(by: rx.disposeBag)
        waitForExpectations(timeout: 1, handler: nil)
    }

    /// 测试推送状态 打开和关闭时，示例 tableView 和 startButton 是否正常显示和隐藏
    func testAuthorizationStatus() {
        let exp = expectation(description: #function)
        let homeViewModel = HomeViewModel()

        let notDeterminedInput = generateInput(authorizationStatus: Observable.just(UNAuthorizationStatus.notDetermined).asSingle())
        let notDeterminedOutput = homeViewModel.transform(input: notDeterminedInput)

        notDeterminedOutput.tableViewHidden.drive { hidden in
            XCTAssertTrue(hidden == false)
        }.disposed(by: rx.disposeBag)

        
        let authorizedInput = generateInput(authorizationStatus: Observable.just(UNAuthorizationStatus.authorized).asSingle())
        let authorizedOutput = homeViewModel.transform(input: authorizedInput)

        authorizedOutput.tableViewHidden.drive { hidden in
            XCTAssertTrue(hidden)
            exp.fulfill()
        }.disposed(by: rx.disposeBag)
        waitForExpectations(timeout: 1, handler: nil)
    }

    /// 生成Input
    private func generateInput(addCustomServerTap: Driver<Void> = Driver.empty(),
                               viewDidAppear: Driver<Void> = Driver.empty(),
                               start: Driver<Void> = Driver.empty(),
                               clientState: Driver<Client.ClienState> = Driver.empty(),
                               authorizationStatus: Single<UNAuthorizationStatus> = Observable.just(UNAuthorizationStatus.authorized).asSingle(),
                               startRequestAuthorizationCreator: @escaping () -> Observable<Bool> = {
                                   Observable.just(true)
                               }) -> HomeViewModel.Input
    {

        return HomeViewModel.Input(
            addCustomServerTap: addCustomServerTap,
            viewDidAppear: viewDidAppear,
            start: start,
            clientState: clientState,
            authorizationStatus: authorizationStatus,
            startRequestAuthorizationCreator: startRequestAuthorizationCreator
        )
    }
}
