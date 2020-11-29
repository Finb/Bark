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
    init( previewModel:PreviewModel, clientState: Driver<Client.ClienState> ) {
        self.previewModel = previewModel
        contentImage = BehaviorRelay<UIImage?>(value: previewModel.image)
        
        super.init()
        
        if let modelTitle = previewModel.title {
            title.accept(modelTitle)
        }
        
        if let modelBody = previewModel.body {
            body.accept(modelBody)
        }
        
        // client State 更改时，重新生成 content
        // 因为这时可能 ServerManager.shared.currentAddress 或 Client.shared.key 发生了改变。
        // 这不是一个好的写法，viewModel 应尽可能只依赖固定的 input ，而不应依赖不可预测的外部变量（ currentAddress 与 key ）。
        // 但这个项目是由 MVC 临时重构为 MVVM ，之前是这样写的，所以懒得改动了。
        clientState.compactMap({[weak self] (_) -> NSAttributedString? in
            return self?.contentAttrStr()
        })
        .drive(content)
        .disposed(by: rx.disposeBag)
        
        
        let noticeStr = "\(previewModel.notice ?? "")"
        let noticeAttrStr = NSMutableAttributedString(string: noticeStr, attributes: [
            NSAttributedString.Key.foregroundColor: Color.grey.base,
            NSAttributedString.Key.font : RobotoFont.regular(with: 12)
        ])
        
        if let moreInfo = previewModel.moreInfo {
            noticeAttrStr.append(NSMutableAttributedString(string: "   \(moreInfo)", attributes: [
                NSAttributedString.Key.foregroundColor: Color.blue.base,
                NSAttributedString.Key.font : RobotoFont.regular(with: 12)
            ]))
        }
        notice.accept(noticeAttrStr)
    }
    
    func contentAttrStr() -> NSAttributedString {
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
        }
        if let modelBody = previewModel.body {
            attrStr.append(NSAttributedString(string: "/\(modelBody)", attributes: [
                NSAttributedString.Key.foregroundColor: Color.grey.base,
                NSAttributedString.Key.font : RobotoFont.regular(with: fontSize)
                ]))
        }
        if let queryParameter = previewModel.queryParameter {
            attrStr.append(NSAttributedString(string: "?\(queryParameter)", attributes: [
                NSAttributedString.Key.foregroundColor: Color.grey.lighten1,
                NSAttributedString.Key.font : RobotoFont.regular(with: fontSize)
                ]))
        }
        
        return attrStr
    }
}
