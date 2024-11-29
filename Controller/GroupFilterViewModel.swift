//
//  GroupFilterViewModel.swift
//  Bark
//
//  Created by huangfeng on 2021/6/8.
//  Copyright © 2021 Fin. All rights reserved.
//

import RealmSwift
import RxCocoa
import RxDataSources
import RxSwift

struct GroupFilterModel {
    var name: String?
    var checked: Bool
}

class GroupFilterViewModel: ViewModel, ViewModelType {
    let groups: [GroupFilterModel]
    init(groups: [GroupFilterModel]) {
        self.groups = groups
    }
    
    struct Input {
        var showAllGroups: Driver<Bool>
        var doneTap: Driver<Void>
    }
    
    struct Output {
        var groups: Driver<[SectionModel<String, GroupCellViewModel>]>
        var isShowAllGroups: Driver<Bool>
        var dismiss: Driver<Void>
    }
    
    var done = PublishRelay<[String?]>()
    
    func transform(input: Input) -> Output {
        // 页面中的群组cellModel
        let groupCellModels = self.groups.map { filterModel in
            GroupCellViewModel(groupFilterModel: filterModel)
        }
        
        // 点击显示所有群组或隐藏所有群组时，设置cell checked 勾选状态
        input.showAllGroups.drive(onNext: { isShowAllGroups in
            for model in groupCellModels {
                model.checked.accept(isShowAllGroups)
            }
        }).disposed(by: rx.disposeBag)
        
        // cell checked 状态改变
        let checkChanged = Observable.merge(groupCellModels.map { model in
            model.checked.asObservable()
        })
        
        // 是否勾选了所有群组
        let isShowAllGroups =
            checkChanged
                .map { _ in
                    groupCellModels.filter { viewModel in
                        viewModel.checked.value
                    }.count >= groupCellModels.count
                }
        input.doneTap.map { () -> [String?] in
            let isShowAllGroups = groupCellModels.filter { viewModel in
                viewModel.checked.value
            }.count >= groupCellModels.count
            if isShowAllGroups {
                return []
            }
            return groupCellModels
                .filter { $0.checked.value }
                .map { $0.name.value }
        }
        .asObservable()
        .bind(to: self.done)
        .disposed(by: rx.disposeBag)
        
        let dismiss = PublishRelay<Void>()
        input.doneTap.map { _ in () }
            .asObservable()
            .bind(to: dismiss)
            .disposed(by: rx.disposeBag)
        
        return Output(
            groups: Driver.just([SectionModel(model: "header", items: groupCellModels)]),
            isShowAllGroups: isShowAllGroups.asDriver(onErrorDriveWith: .empty()),
            dismiss: dismiss.asDriver(onErrorDriveWith: .empty())
        )
    }
}
