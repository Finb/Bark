//
//  Reusable.swift
//  Bark
//
//  Created by huangfeng on 2020/11/17.
//  Copyright © 2020 Fin. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

private var prepareForReuseBag: Int8 = 0

@objc public protocol Reusable : class {
    func prepareForReuse()
}

extension UITableViewCell: Reusable {}
extension UITableViewHeaderFooterView: Reusable {}
extension UICollectionReusableView: Reusable {}

extension Reactive where Base: Reusable {
    var prepareForReuse: Observable<Void> {
        return Observable.of(sentMessage(#selector(Base.prepareForReuse)).map { _ in }, deallocated).merge()
    }
    
    var reuseBag: DisposeBag {
        MainScheduler.ensureExecutingOnScheduler()
        
        if let bag = objc_getAssociatedObject(base, &prepareForReuseBag) as? DisposeBag {
            return bag
        }
        
        let bag = DisposeBag()
        objc_setAssociatedObject(base, &prepareForReuseBag, bag, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        
        _ = sentMessage(#selector(Base.prepareForReuse))
            .subscribe(onNext: { [weak base] _ in
                guard let strongBase = base else {
                    return
                }
                let newBag = DisposeBag()
                objc_setAssociatedObject(strongBase, &prepareForReuseBag, newBag, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            })
        
        return bag
    }
}
