//
//  Observable+Extension.swift
//  Bark
//
//  Created by huangfeng on 2018/6/25.
//  Copyright © 2018 Fin. All rights reserved.
//

import UIKit

import UIKit
import RxSwift
import ObjectMapper
import SwiftyJSON
import Moya

public enum ApiError : Swift.Error {
    case Error(info: String)
    case AccountBanned(info: String)
}

extension Swift.Error {
    func rawString() -> String {
        guard let err = self as? ApiError else {
            return self.localizedDescription
        }
        switch err {
        case let .Error(info):
            return info
        case let .AccountBanned(info):
            return info
        }
    }
}

extension Observable where Element: Moya.Response {
    /// 过滤 HTTP 错误，例如超时，请求失败等
    func filterHttpError() -> Observable<Element> {
        return filter{ response in
            if (200...209) ~= response.statusCode {
                return true
            }
            print("网络错误")
            throw ApiError.Error(info: "网络错误")
        }
    }
    
    /// 过滤逻辑错误，例如协议里返回 错误CODE
    func filterResponseError() -> Observable<JSON> {
        return filterHttpError().map({ (response) -> JSON in
             let json = try JSON(data: response.data)
             var msg:String?
            if json["message"].exists() {
                msg = json["message"].rawString()!
            }
            if response.statusCode != 200 {
                 throw ApiError.Error(info: msg ?? "未知错误")
            }
            return json
        })
    }
    
    /// 将Response 转换成 JSON Model
    ///
    /// - Parameters:
    ///   - typeName: 要转换的Model Class
    ///   - dataPath: 从哪个节点开始转换，例如 ["data","links"]
    func mapResponseToObj<T: Mappable>(_ typeName: T.Type , dataPath:[String] = ["data"] ) -> Observable<T> {
        return filterResponseError().map{ json in
            var rootJson  = json
            if dataPath.count > 0{
                rootJson = rootJson[dataPath]
            }
            if let model: T = self.resultFromJSON(json: rootJson)  {
                return model
            }
            else{
                throw ApiError.Error(info: "json 转换失败")
            }
        }
    }
    
    /// 将Response 转换成 JSON Model Array
    func mapResponseToObjArray<T: Mappable>(_ type: T.Type, dataPath:[String] = ["data"] ) -> Observable<[T]> {
        return filterResponseError().map{ json in
            var rootJson = json;
            if dataPath.count > 0{
                rootJson = rootJson[dataPath]
            }
            var result = [T]()
            guard let jsonArray = rootJson.array else{
                return result
            }
            
            for json in  jsonArray{
                if let jsonModel: T = self.resultFromJSON(json: json) {
                    result.append(jsonModel)
                }
                else{
                    throw ApiError.Error(info: "json 转换失败")
                }
            }
            
            return result
        }
    }
    
    private func resultFromJSON<T: Mappable>(jsonString:String) -> T? {
        return T(JSONString: jsonString)
    }
    private func resultFromJSON<T: Mappable>(json:JSON) -> T? {
        if let str = json.rawString(){
            return resultFromJSON(jsonString: str)
        }
        return nil
    }
}
