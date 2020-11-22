//
//  MJRefresh+Rx.swift
//  Bark
//
//  Created by huangfeng on 2020/11/22.
//  Copyright © 2020 Fin. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import MJRefresh

extension Reactive where Base : MJRefreshComponent {
    var refresh: ControlEvent<Void> {
        
        let source = Observable<Void>.create {[weak control = self.base] (observer) -> Disposable in
            MainScheduler.ensureExecutingOnScheduler()
            guard let control = control else {
                observer.onCompleted()
                return Disposables.create()
            }
            control.refreshingBlock = {
                observer.onNext(())
            }
            return Disposables.create()
        }
        return ControlEvent(events: source)
    }
    
}


enum MJRefreshAction {
    /// 不做任何事情
    case none
    /// 开始刷新
    case begainRefresh
    /// 停止刷新
    case endRefresh
    /// 开始加载更多
    case begainLoadmore
    /// 停止加载更多
    case endLoadmore
    /// 显示无更多数据
    case showNomoreData
    /// 重置无更多数据
    case resetNomoreData
}

extension Reactive where Base:UIScrollView {
    
    /// 执行的操作类型
    var refreshAction:Binder<MJRefreshAction> {
        
        return Binder(base) { (target, action) in
            
            switch action{
            case .begainRefresh:
                if let header =  target.mj_header {
                    header.beginRefreshing()
                }
            case .endRefresh:
                if let header =  target.mj_header {
                    header.endRefreshing()
                }
            case .begainLoadmore:
                if let footer =  target.mj_footer {
                    footer.beginRefreshing()
                }
            case .endLoadmore:
                if let footer =  target.mj_footer {
                    footer.endRefreshing()
                }
            case .showNomoreData:
                if let footer =  target.mj_footer {
                    footer.endRefreshingWithNoMoreData()
                }
            case .resetNomoreData:
                if let footer =  target.mj_footer {
                    footer.resetNoMoreData()
                }
                break
            case .none:
                break
            }
        }
    }
    
}
