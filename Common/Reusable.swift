//
//  Reusable.swift
//  Bark
//
//  Created by huangfeng on 2020/11/17.
//  Copyright © 2020 Fin. All rights reserved.
//

import RxCocoa
import RxSwift
import UIKit

private var prepareForReuseBag: Int8 = 0

@objc public protocol Reusable: AnyObject {
    func prepareForReuse()
}

extension UITableViewCell: Reusable {}
extension UITableViewHeaderFooterView: Reusable {}
extension UICollectionReusableView: Reusable {}

extension Reactive where Base: Reusable {
    var reuseBag: DisposeBag {
        MainScheduler.ensureExecutingOnScheduler()

        if let bag = objc_getAssociatedObject(base, &prepareForReuseBag) as? DisposeBag {
            return bag
        }

        let bag = DisposeBag()
        objc_setAssociatedObject(base, &prepareForReuseBag, bag, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)

        _ = sentMessage(#selector(Base.prepareForReuse))
            .take(until: deallocated)
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
