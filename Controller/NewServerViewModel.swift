//
//  NewServerViewModel.swift
//  Bark
//
//  Created by huangfeng on 2020/11/18.
//  Copyright © 2020 Fin. All rights reserved.
//

import Foundation
import Moya
import RxCocoa
import RxSwift
import SwiftyJSON

class NewServerViewModel: ViewModel, ViewModelType {
    struct Input {
        var noticeClick: Driver<Void>
        var done: Driver<String>
        var viewDidAppear: Driver<Void>
        var didScan: Driver<String>
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
            .map { URL(string: NSLocalizedString("deployUrl"))! }
            .asDriver()
        
        input.viewDidAppear
            .map { "https://" }
            .asObservable()
            .take(1)
            .subscribe(onNext: { text in
                showKeyboard.accept(true)
                urlText.accept(text)
            }).disposed(by: rx.disposeBag)
        
        input.didScan.compactMap { text in
            URL(string: text)
        }.drive(onNext: { url in
            urlText.accept(url.absoluteString)
        }).disposed(by: rx.disposeBag)
        
        input.done
            .asObservable()
            .flatMapLatest { [weak self] url -> Observable<Result<JSON, ApiError>> in
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
            .subscribe(onNext: { [weak self] response in
                guard let strongSelf = self else { return }
                switch response {
                case .success:
                    let server = Server(address: strongSelf.url, key: "")
                    ServerManager.shared.addServer(server: server)
                    ServerManager.shared.setCurrentServer(serverId: server.id)
                    ServerManager.shared.syncAllServers()
                    
                    strongSelf.pop.accept(URL(string: strongSelf.url)?.host ?? "")
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
