//
//  MessageListViewModel.swift
//  Bark
//
//  Created by huangfeng on 2020/11/21.
//  Copyright © 2020 Fin. All rights reserved.
//

import Foundation
import RxSwift
import RxDataSources
import RxCocoa
import RealmSwift

class MessageListViewModel: ViewModel,ViewModelType {
    struct Input {
        var settingClick: Driver<Void>
        var loadMore: Driver<Void>
        var itemDelete: Driver<IndexPath>
        var itemSelected: Driver<MessageTableViewCellViewModel>
    }
    
    struct Output {
        var messages:Driver<[MessageSection]>
        var settingClick: Driver<MessageSettingsViewModel>
        var refreshAction:Driver<MJRefreshAction>
        var alertMessage:Driver<String>
        var urlTap:Driver<URL>
    }
    
    let results:Results<Message>? = {
        if let realm = try? Realm() {
            return realm.objects(Message.self)
                .filter("isDeleted != true")
                .sorted(byKeyPath: "createDate", ascending: false)
        }
        return nil
    }()
    
    var page = 0
    let pageCount = 20
    func getNextPage() -> [Message] {
        if let result = results {
            let startIndex = page * pageCount
            let endIndex = min(startIndex + pageCount, result.count)
            guard endIndex > startIndex else {
                return []
            }
            var messages:[Message] = []
            for i in startIndex ..< endIndex {
                messages.append(result[i])
            }
            page += 1
            return messages
        }
        return []
    }
    
    
    func transform(input: Input) -> Output {
        let settingClick = input.settingClick
            .map{
                MessageSettingsViewModel()
            }
            .asDriver()
        
        let alertMessage = input.itemSelected.map { (model) -> String in
            let message = model.message
            
            var copyContent:String = ""
            if let title = message.title {
                copyContent += "\(title)\n"
            }
            if let body = message.body {
                copyContent += "\(body)\n"
            }
            if let url = message.url {
                copyContent += "\(url)\n"
            }
            copyContent = String(copyContent.prefix(copyContent.count - 1))
            
            return copyContent
        }
        
        
        //数据源
        let messagesRelay = BehaviorRelay<[MessageSection]>(value: [])
        let refreshAction = BehaviorRelay<MJRefreshAction>(value: .none)
        
        Observable<Void>.just(())
            .concat(input.loadMore)
            .subscribe(onNext: {[weak self] in
                guard let strongSelf = self else { return }
                let messages = strongSelf.getNextPage()
                let cellViewModels =  messages.map({ (message) -> MessageTableViewCellViewModel in
                    return MessageTableViewCellViewModel(message: message)
                })
                
                refreshAction.accept(.endLoadmore)
                if var section = messagesRelay.value.first {
                    section.messages.append(contentsOf: cellViewModels)
                    messagesRelay.accept([section])
                }
                else{
                    messagesRelay.accept([MessageSection(header: "model", messages: cellViewModels)])
                }
            }).disposed(by: rx.disposeBag)
        
        //删除message
        input.itemDelete.drive(onNext: {[weak self] indexPath in
            if var section = messagesRelay.value.first {
                if let realm = try? Realm() {
                    try? realm.write {
                        let message = self?.results?[indexPath.row]
                        message?.isDeleted = true
                    }
                }
                section.messages.remove(at: indexPath.row)
                messagesRelay.accept([section])
            }
        }).disposed(by: rx.disposeBag)
        
        // cell 中点击 url。
        let urlTap = messagesRelay.flatMapLatest { (section) -> Observable<String> in
            if let section = section.first {
                let taps = section.messages.compactMap { (model) -> Observable<String> in
                    return model.urlTap.asObservable()
                }
                return Observable.merge(taps)
            }
            return .empty()
        }
        .compactMap { URL(string: $0) } //只处理正确的url
        
        
        
        return Output(
            messages: messagesRelay.asDriver(onErrorJustReturn: []),
            settingClick: settingClick,
            refreshAction: refreshAction.asDriver(),
            alertMessage: alertMessage,
            urlTap: urlTap.asDriver(onErrorDriveWith: .empty())
        )
    }
}
