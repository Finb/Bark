//
//  Observable+Extension.swift
//  Bark
//
//  Created by huangfeng on 2018/6/25.
//  Copyright © 2018 Fin. All rights reserved.
//

import UIKit

import Moya
import ObjectMapper
import RxSwift
import SwiftyJSON
import UIKit

extension Observable where Element: Moya.Response {
    /// 过滤 HTTP 错误，例如超时，请求失败等
    func filterHttpError() -> Observable<Result<Element, ApiError>> {
        return catchAndReturn(Element(statusCode: 599, data: Data()))
            .map { response -> Result<Element, ApiError> in
                if (200...209) ~= response.statusCode {
                    return .success(response)
                } else {
                    return .failure(ApiError.Error(info: "网络错误"))
                }
            }
    }
    
    /// 过滤逻辑错误，例如协议里返回 错误CODE
    func filterResponseError() -> Observable<Result<JSON, ApiError>> {
        return filterHttpError()
            .map { response -> Result<JSON, ApiError> in
                switch response {
                case .success(let element):
                    do {
                        let json = try JSON(data: element.data)
                        
                        if let codeStr = json["code"].rawString(),
                           let code = Int(codeStr),
                           code == 200
                        {
                            return .success(json)
                        } else {
                            var msg: String = ""
                            if json["message"].exists() {
                                msg = json["message"].rawString()!
                            }
                            return .failure(ApiError.Error(info: msg))
                        }
                    } catch {
                        return .failure(ApiError.Error(info: error.rawString()))
                    }
                case .failure(let error):
                    return .failure(ApiError.Error(info: error.rawString()))
                }
            }
    }
    
    /// 将Response 转换成 JSON Model
    ///
    /// - Parameters:
    ///   - typeName: 要转换的Model Class
    ///   - dataPath: 从哪个节点开始转换，例如 ["data","links"]
    func mapResponseToObj<T: Mappable>(_ typeName: T.Type, dataPath: [String] = ["data"]) -> Observable<Result<T, ApiError>> {
        return filterResponseError().map { json in
            switch json {
            case .success(let json):
                var rootJson = json
                if dataPath.count > 0 {
                    rootJson = rootJson[dataPath]
                }
                if let model: T = self.resultFromJSON(json: rootJson) {
                    return .success(model)
                } else {
                    return .failure(ApiError.Error(info: "json 转换失败"))
                }
            case .failure(let error):
                return .failure(error)
            }
        }
    }
    
    /// 将Response 转换成 JSON Model Array
    func mapResponseToObjArray<T: Mappable>(_ type: T.Type, dataPath: [String] = ["data"]) -> Observable<Result<[T], ApiError>> {
        return filterResponseError().map { json in
            switch json {
            case .success(let json):
                var rootJson = json
                if dataPath.count > 0 {
                    rootJson = rootJson[dataPath]
                }
                var result = [T]()
                guard let jsonArray = rootJson.array else {
                    return .failure(ApiError.Error(info: "Root Json 不是 Array"))
                }
                
                for json in jsonArray {
                    if let jsonModel: T = self.resultFromJSON(json: json) {
                        result.append(jsonModel)
                    } else {
                        return .failure(ApiError.Error(info: "json 转换失败"))
                    }
                }
                
                return .success(result)
            case .failure(let error):
                return .failure(error)
            }
        }
    }
    
    private func resultFromJSON<T: Mappable>(jsonString: String) -> T? {
        return T(JSONString: jsonString)
    }

    private func resultFromJSON<T: Mappable>(json: JSON) -> T? {
        if let str = json.rawString() {
            return resultFromJSON(jsonString: str)
        }
        return nil
    }
}
