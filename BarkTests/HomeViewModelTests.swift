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

    let homeViewModel = HomeViewModel()
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testNewButtonClick() {
        let exp = expectation(description: #function)

        let input = HomeViewModel.Input(
            addCustomServerTap: Driver.just(()),
            viewDidAppear: Driver.empty(),
            start: Driver.empty(),
            clientState: Driver.empty())
        let output = homeViewModel.transform(input: input)

        output.push.drive { viewModel in
            XCTAssertNotNil(viewModel as? NewServerViewModel)
            exp.fulfill()
        }.disposed(by: rx.disposeBag)

        waitForExpectations(timeout: 1, handler: nil)
    }
}
