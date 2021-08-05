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
        var refresh: Driver<Void>
        var loadMore: Driver<Void>
        var itemDelete: Driver<IndexPath>
        var itemSelected: Driver<MessageTableViewCellViewModel>
        var delete: Driver<MessageDeleteType>
        var groupTap: Driver<Void>
        var searchText: Observable<String?>
    }
    
    struct Output {
        var messages: Driver<[MessageSection]>
        var refreshAction: Driver<MJRefreshAction>
        var alertMessage: Driver<String>
        var urlTap: Driver<URL>
        var groupFilter: Driver<GroupFilterViewModel>
        var title: Driver<String>
    }
    
    private var results:Results<Message>?
    
    //根据群组获取消息
    private func getResults(filterGroups:[String?], searchText:String?) -> Results<Message>? {
        if let realm = try? Realm() {
            var results = realm.objects(Message.self)
                .filter("isDeleted != true")
                .sorted(byKeyPath: "createDate", ascending: false)
            if filterGroups.count > 0 {
                results = results.filter("group in %@", filterGroups)
            }
            if let text = searchText, text.count > 0 {
                results = results.filter("title contains[c] '\(text)' or body contains[c] '\(text)'")
            }
            return results
        }
        return nil
    }
    
    private var page = 0
    private let pageCount = 20
    private func getNextPage() -> [Message] {
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
        // 标题
        let titleRelay = BehaviorRelay<String>(value: NSLocalizedString("historyMessage"))
        // 数据源
        let messagesRelay = BehaviorRelay<[MessageSection]>(value: [])
        // 刷新操作
        let refreshAction = BehaviorRelay<MJRefreshAction>(value: .none)
        // 切换群组
        let filterGroups: BehaviorRelay<[String?]> = {
            if let groups:[String?] = Settings["me.fin.filterGroups"] {
                return BehaviorRelay<[String?]>(value: groups)
            }
            return BehaviorRelay<[String?]>(value: [])
        }()
        
        // Message 转 MessageSection
        func messagesToMessageSection(messages:[Message]) -> [MessageSection] {
            let cellViewModels = messages.map({ (message) -> MessageTableViewCellViewModel in
                return MessageTableViewCellViewModel(message: message)
            })
            return [MessageSection(header: "model", messages: cellViewModels)]
        }
        //切换分组时，更新分组名
        filterGroups
            .subscribe(onNext: {filterGroups in
                if filterGroups.count <= 0 {
                    titleRelay.accept(NSLocalizedString("historyMessage"))
                }
                else{
                    titleRelay.accept(filterGroups.map { $0 ?? NSLocalizedString("default") }.joined(separator: " , "))
                }
            }).disposed(by: rx.disposeBag)
        
        //切换分组和更改搜索词时，更新数据源
        Observable
            .combineLatest(filterGroups, input.searchText)
            .subscribe(onNext: {[weak self] groups, searchText in
                self?.results = self?.getResults(filterGroups: groups, searchText: searchText)
            }).disposed(by: rx.disposeBag)

        //切换分组和下拉刷新时，重新刷新列表
        Observable
            .merge(
                input.refresh.asObservable().map{ () },
                filterGroups.map{ _ in () },
                input.searchText.asObservable().map{ _ in () }
            )
            .subscribe(onNext: {[weak self]  in
                guard let strongSelf = self else { return }
                strongSelf.page = 0
                messagesRelay.accept(
                    messagesToMessageSection(
                        messages: strongSelf.getNextPage()
                    )
                )
                refreshAction.accept(.endRefresh)
            }).disposed(by: rx.disposeBag)
        
        //加载更多
        input.loadMore.asObservable()
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
        
        //批量删除
        input.delete.drive(onNext: {[weak self] type in
            guard let strongSelf = self else { return }
            
            var date = Date()
            switch type {
            case .allTime:
                date = Date(timeIntervalSince1970: 0)
            case .todayAndYesterday:
                date = Date.yesterday
            case .today:
                date = Date().noon
            case .lastHour:
                date = Date.lastHour
            }
            
            if let realm = try? Realm() {
                guard let messages = strongSelf.getResults(filterGroups: filterGroups.value, searchText: nil)?.filter("createDate >= %@", date) else {
                    return
                }
                try? realm.write{
                    for msg in messages {
                        msg.isDeleted = true
                    }
                }
            }
            
            strongSelf.page = 0
            messagesRelay.accept(messagesToMessageSection(messages: strongSelf.getNextPage()))
            
        }).disposed(by: rx.disposeBag)
        
        //群组筛选
        let groupFilter = input.groupTap.compactMap {() -> GroupFilterViewModel? in
            if let realm = try? Realm() {
                let groups = realm.objects(Message.self)
                    .filter("isDeleted != true")
                    .distinct(by: ["group"])
                    .value(forKeyPath: "group") as? [String?]
                
                let groupModels = groups?.compactMap({ groupName -> GroupFilterModel in
                    var check = true
                    if filterGroups.value.count > 0 {
                        check = filterGroups.value.contains(groupName)
                    }
                    return GroupFilterModel(name: groupName, checked: check)
                })
                
                if let models = groupModels {
                    let viewModel = GroupFilterViewModel(groups: models)
                    
                    //保存选择的 group
                    viewModel.done.subscribe(onNext: { filterGroups in
                        Settings["me.fin.filterGroups"] = filterGroups
                    }).disposed(by: viewModel.rx.disposeBag)
                    
                    //将选择绑定到当前页面
                    viewModel.done
                        .bind(to: filterGroups)
                        .disposed(by: viewModel.rx.disposeBag)
                    return viewModel
                }
            }
            return nil
        }
        
        return Output(
            messages: messagesRelay.asDriver(onErrorJustReturn: []),
            refreshAction: refreshAction.asDriver(),
            alertMessage: alertMessage,
            urlTap: urlTap.asDriver(onErrorDriveWith: .empty()),
            groupFilter: groupFilter.asDriver(),
            title: titleRelay.asDriver()
        )
    }
}
