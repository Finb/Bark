//
//  String+Extension.swift
//  Bark
//
//  Created by huangfeng on 2018/6/26.
//  Copyright © 2018 Fin. All rights reserved.
//

import UIKit

extension String {
    //将原始的url编码为合法的url
    func urlEncoded() -> String {
        let encodeUrlString = self.addingPercentEncoding(withAllowedCharacters:
            .urlQueryAllowed)
        return encodeUrlString ?? ""
    }
    
    //将编码后的url转换回原始的url
    func urlDecoded() -> String {
        return self.removingPercentEncoding ?? ""
    }
}
