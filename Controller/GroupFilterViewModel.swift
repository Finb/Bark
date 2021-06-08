//
//  GroupFilterViewModel.swift
//  Bark
//
//  Created by huangfeng on 2021/6/8.
//  Copyright © 2021 Fin. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources
import RxCocoa
import RealmSwift
struct GroupFilterModel {
    var name:String?
    var checked:Bool
}
class GroupFilterViewModel: ViewModel,ViewModelType {
    let groups:[GroupFilterModel]
    init(groups:[GroupFilterModel]) {
        self.groups = groups
    }
    
    struct Input {
        var showAllGroups:Driver<Bool>
    }
    
    struct Output {
        var groups:Driver<[ SectionModel<String, GroupCellViewModel>]>
        var isShowAllGroups:Driver<Bool>
    }
    
    func transform(input: Input) -> Output {
        
        // 页面中的群组cellModel
        let groupCellModels = self.groups.map({ filterModel in
            return GroupCellViewModel(groupFilterModel: filterModel)
        })
        
        //点击显示所有群组或隐藏所有群组时，设置cell checked 勾选状态
        input.showAllGroups.drive(onNext: { isShowAllGroups in
            groupCellModels.forEach { model  in
                model.checked.accept(isShowAllGroups)
            }
        }).disposed(by: rx.disposeBag)
        
        //cell checked 状态改变
        let checkChanged = Observable.merge(groupCellModels.map { model in
            return model.checked.asObservable()
        })
        
        // 是否勾选了所有群组
        let isShowAllGroups =
            checkChanged
            .map{_ in
                return groupCellModels.filter { viewModel in
                    return viewModel.checked.value
                }.count >= groupCellModels.count
            }

        return Output(
            groups: Driver.just([ SectionModel(model: "header", items: groupCellModels) ]),
            isShowAllGroups: isShowAllGroups.asDriver(onErrorDriveWith: .empty())
        )
    }
    
}

