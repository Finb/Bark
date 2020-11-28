//
//  NewServerViewModel.swift
//  Bark
//
//  Created by huangfeng on 2020/11/18.
//  Copyright © 2020 Fin. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import SwiftyJSON
import Moya

class NewServerViewModel: ViewModel, ViewModelType {
    struct Input {
        var noticeClick:Driver<Void>
        var done: Driver<String>
        var viewDidAppear: Driver<Void>
    }
    
    struct Output {
        var showKeyboard: Driver<Bool>
        var notice: Driver<URL>
        var urlText: Driver<String>
        var showSnackbar: Driver<String>
        var pop: Driver<String>
    }
    
    
    private var url: String = ""
    
    let pop = PublishRelay<String>()
    
    func transform(input: Input) -> Output {
        
        let showKeyboard = PublishRelay<Bool>()
        let urlText = PublishRelay<String>()
        let showSnackbar = PublishRelay<String>()

        let notice = input.noticeClick
            .map{ URL(string: "https://day.app/2018/06/bark-server-document/")! }
            .asDriver()
        
        input.viewDidAppear
            .map{ "https://" }
            .asObservable()
            .take(1)
            .subscribe(onNext: { text in
                showKeyboard.accept(true)
                urlText.accept(text)
            }).disposed(by: rx.disposeBag)
        
        input.done
            .asObservable()
            .flatMapLatest {[weak self] (url) -> Observable<Result<JSON,ApiError>> in
                showKeyboard.accept(false)
                if let _ = URL(string: url) {
                    guard let strongSelf = self else { return .empty() }
                    strongSelf.url = url
                    return BarkApi.provider
                        .request(.ping(baseURL: url))
                        .filterResponseError()
                }
                else {
                    showSnackbar.accept(NSLocalizedString("InvalidURL"))
                    return .empty()
                }
            }
            .subscribe(onNext: {[weak self] response in
                guard let strongSelf = self else { return }
                switch response {
                case .success:
                    ServerManager.shared.currentAddress = strongSelf.url
                    Client.shared.bindDeviceToken()
                    
                    strongSelf.pop.accept(strongSelf.url)
                    showSnackbar.accept(NSLocalizedString("AddedSuccessfully"))
                case .failure(let error):
                    showSnackbar.accept("\(NSLocalizedString("InvalidServer"))\(error.rawString())")
                }
            }).disposed(by: rx.disposeBag)

        return Output(
            showKeyboard: showKeyboard.asDriver(onErrorDriveWith: .empty()),
            notice: notice,
            urlText: urlText.asDriver(onErrorDriveWith: .empty()),
            showSnackbar: showSnackbar.asDriver(onErrorDriveWith: .empty()),
            pop: pop.asDriver(onErrorDriveWith: .empty())
        )
    }
}
