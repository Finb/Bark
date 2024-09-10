//
//  SectionViewModel-iPad.swift
//  Bark
//
//  Created by sidguan on 2024/7/1.
//  Copyright © 2024 Fin. All rights reserved.
//

import Foundation
import RxCocoa
import RxDataSources
import RxSwift
import Material

struct SectionItem {
    let image: UIImage?
    let title: String
}

class SectionViewModel: ViewModel, ViewModelType {
    struct Input {
//        var sectionSelected: Driver<SectionItem>
    }
    
    struct Output {
        var items: Observable<[SectionModel<String, SectionItem>]>
//        var selectedItem: Observable<SectionItem?>
    }
    
    func initSectionItems() -> Observable<[SectionModel<String, SectionItem>]> {
        let sectionItems = [
            SectionItem(image: UIImage(named: "baseline_gite_black_24pt"), title: NSLocalizedString("service")),
            SectionItem(image: Icon.history, title: NSLocalizedString("historyMessage")),
            SectionItem(image: UIImage(named: "baseline_manage_accounts_black_24pt"), title: NSLocalizedString("settings")),
        ]
        let section = [SectionModel(model: "", items: sectionItems)]
        return Observable.just(section)
    }
    
    func transform(input: Input) -> Output {
        let sectionItems = initSectionItems()
        return Output(
            items: sectionItems
        )
    }
}
