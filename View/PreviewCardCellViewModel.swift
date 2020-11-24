//
//  PreviewCardCellViewModel.swift
//  Bark
//
//  Created by huangfeng on 2020/11/23.
//  Copyright © 2020 Fin. All rights reserved.
//

import Foundation
import Material
import RxCocoa
class PreviewCardCellViewModel: ViewModel {
    let title = BehaviorRelay(value: "")
    let body = BehaviorRelay(value: "")
    let content = BehaviorRelay(value: NSAttributedString())
    let notice = BehaviorRelay(value: NSAttributedString())
    let contentImage: BehaviorRelay<UIImage?>
    
    let noticeTap = PublishRelay<ViewModel>()
    let copy = PublishRelay<String>()
    let preview = PublishRelay<URL>()
    
    let previewModel:PreviewModel
    init( previewModel:PreviewModel ) {
        self.previewModel = previewModel
        
        var fontSize:CGFloat = 14
        if UIScreen.main.bounds.size.width <= 320 {
            fontSize = 11
        }
        let serverUrl = URL(string: ServerManager.shared.currentAddress)!
        let attrStr = NSMutableAttributedString(string: "")
        attrStr.append(NSAttributedString(string: serverUrl.absoluteString, attributes: [
            NSAttributedString.Key.foregroundColor: Color.grey.darken4,
            NSAttributedString.Key.font : RobotoFont.regular(with: fontSize)
            ]))
        
        attrStr.append(NSAttributedString(string: "/\(Client.shared.key ?? "Your Key")", attributes: [
            NSAttributedString.Key.foregroundColor: Color.grey.darken3,
            NSAttributedString.Key.font : RobotoFont.regular(with: fontSize)
            ]))
        
        if let modelTitle = previewModel.title {
            attrStr.append(NSAttributedString(string: "/\(modelTitle)", attributes: [
                NSAttributedString.Key.foregroundColor: Color.grey.darken1,
                NSAttributedString.Key.font : RobotoFont.regular(with: fontSize)
                ]))
            title.accept(modelTitle)
        }
        if let modelBody = previewModel.body {
            attrStr.append(NSAttributedString(string: "/\(modelBody)", attributes: [
                NSAttributedString.Key.foregroundColor: Color.grey.base,
                NSAttributedString.Key.font : RobotoFont.regular(with: fontSize)
                ]))
            body.accept(modelBody)
        }
        if let queryParameter = previewModel.queryParameter {
            attrStr.append(NSAttributedString(string: "?\(queryParameter)", attributes: [
                NSAttributedString.Key.foregroundColor: Color.grey.lighten1,
                NSAttributedString.Key.font : RobotoFont.regular(with: fontSize)
                ]))
        }
        content.accept(attrStr)
        
        if let moreInfo = previewModel.moreInfo {
            let noticeStr = "\(previewModel.notice ?? "")  \(moreInfo)"
            let noticeAttrStr = NSMutableAttributedString(string: noticeStr, attributes: [
                NSAttributedString.Key.foregroundColor: Color.grey.base,
                NSAttributedString.Key.font : RobotoFont.regular(with: 12)
            ])
            noticeAttrStr.setAttributes([
                NSAttributedString.Key.foregroundColor: Color.blue.base,
                NSAttributedString.Key.font : RobotoFont.regular(with: 12)
            ], range: NSRange(location: noticeStr.count - moreInfo.count, length: moreInfo.count))
            
            notice.accept(noticeAttrStr)
        }
        else  {
            let noticeStr = "\(previewModel.notice ?? "")"
            let noticeAttrStr = NSMutableAttributedString(string: noticeStr, attributes: [
                NSAttributedString.Key.foregroundColor: Color.grey.base,
                NSAttributedString.Key.font : RobotoFont.regular(with: 12)
            ])
            notice.accept(noticeAttrStr)
        }
        
        contentImage = BehaviorRelay<UIImage?>(value: previewModel.image)
        
        super.init()
    }
}
