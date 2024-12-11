//
//  PreviewModel.swift
//  Bark
//
//  Created by huangfeng on 2020/11/23.
//  Copyright © 2020 Fin. All rights reserved.
//

import Foundation
import UIKit

class PreviewModel: NSObject {
    var title: String?
    var body: String?
    var notice: String?
    var queryParameter: String?
    var image: UIImage?
    var moreInfo: String?
    var moreViewModel: ViewModel?

    init(title: String? = nil,
         body: String? = nil,
         notice: String? = nil,
         queryParameter: String? = nil,
         image: UIImage? = nil,
         moreInfo: String? = nil,
         moreViewModel: ViewModel? = nil)
    {
        self.title = title
        self.body = body
        self.notice = notice
        self.queryParameter = queryParameter
        self.image = image
        self.moreInfo = moreInfo
        self.moreViewModel = moreViewModel
    }
}
