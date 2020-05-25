//
//  BarkTargetType.swift
//  Bark
//
//  Created by huangfeng on 2018/6/25.
//  Copyright © 2018 Fin. All rights reserved.
//

import UIKit
import Moya
import RxSwift

//保存全局Providers
fileprivate var retainProviders:[String: Any] = [:]

protocol BarkTargetType: TargetType {
    var parameters: [String: Any]? { get }
}

extension BarkTargetType {
    var headers: [String : String]? {
        return nil
    }
    var baseURL: URL {
        return URL(string: ServerManager.shared.currentAddress)!
    }
    
    var method: Moya.Method {
        return .get
    }
    
    var parameterEncoding: ParameterEncoding {
        return URLEncoding.default
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        return requestTaskWithParameters
    }
    
    var requestTaskWithParameters: Task {
        get {
            //默认参数
            var defaultParameters:[String:Any] = [:]
            //协议参数
            if let parameters = self.parameters {
                for (key, value) in parameters {
                    defaultParameters[key] = value
                }
            }
            return Task.requestParameters(parameters: defaultParameters, encoding: parameterEncoding)
        }
    }
    
    static var networkActivityPlugin: PluginType {
        return NetworkActivityPlugin { (change, type) in
            switch change {
            case .began:
                dispatch_sync_safely_main_queue {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = true
                }
            case .ended:
                dispatch_sync_safely_main_queue {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
            }
        }
    }
    
    /// 实现此协议的类，将自动获得用该类实例化的 provider 对象
    static var provider: RxSwift.Reactive< MoyaProvider<Self> > {
        let key = "\(Self.self)"
        if let provider = retainProviders[key] as? RxSwift.Reactive< MoyaProvider<Self> > {
            return provider
        }
        let provider = Self.weakProvider
        retainProviders[key] = provider
        return provider
    }
    
    /// 不被全局持有的 Provider ，使用时，需要持有它，否则将立即释放，请求随即终止
    static var weakProvider: RxSwift.Reactive< MoyaProvider<Self> > {
        var plugins:[PluginType] = [networkActivityPlugin]
        #if DEBUG
        plugins.append(LogPlugin())
        #endif
        let provider = MoyaProvider<Self>(plugins:plugins)
        return provider.rx
    }
}

extension RxSwift.Reactive where Base: MoyaProviderType {
    public func request(_ token: Base.Target, callbackQueue: DispatchQueue? = nil) -> Observable<Response> {
        return Single.create { [weak base] single in
            let cancellableToken = base?.request(token, callbackQueue: callbackQueue, progress: nil) { result in
                switch result {
                case let .success(response):
                    single(.success(response))
                case let .failure(error):
                    single(.error(error))
                }
            }
            
            return Disposables.create {
                cancellableToken?.cancel()
            }
            }.asObservable()
    }
}

fileprivate class LogPlugin: PluginType{
    func willSend(_ request: RequestType, target: TargetType) {
        print("\n-------------------\n准备请求: \(target.path)")
        print("请求方式: \(target.method.rawValue)")
        if let params = (target as? BarkTargetType)?.parameters {
            print(params)
        }
        print("\n")
        
    }
    func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        print("\n-------------------\n请求结束: \(target.path)")
        if let data = try? result.get().data, let resutl = String(data: data, encoding: String.Encoding.utf8) {
            print("请求结果: \(resutl)")
        }
        print("\n")
    }
}
