//
//  PreviewCardCell.swift
//  Bark
//
//  Created by huangfeng on 2018/6/26.
//  Copyright © 2018 Fin. All rights reserved.
//

import UIKit
import Material

class PreviewModel: NSObject {
    var title:String?
    var body:String?
    var category:String?
    var notice:String?
    
    init(title:String? = nil, body:String? = nil, category:String? = nil, notice:String? = nil) {
        self.title = title
        self.body = body
        self.category = category
        self.notice = notice
    }
}

class PreviewCardCell: UITableViewCell {

    let previewButton = IconButton(image: Icon.cm.skipForward, tintColor: Color.grey.base)
    let copyButton = IconButton(image: UIImage(named: "baseline_file_copy_white_24pt"), tintColor: Color.grey.base)
    let toolbar = Toolbar()
    
    let noticeLabel: UILabel = {
        let label = UILabel()
        label.font = RobotoFont.regular(with: 12)
        label.textColor = Color.grey.base
        label.numberOfLines = 0
        return label
    }()

    let bottomBar = Bar()
    
    let card = Card()
    
    var copyHandler: (() -> Void)?
    
    let contentLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = RobotoFont.regular(with: 14)
        return label
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = Color.grey.lighten3
        
        self.transition([ .scale(0.75) , .opacity(0)] )
        
        self.toolbar.rightViews = [copyButton,previewButton]
        self.bottomBar.leftViews = [noticeLabel]
        
        toolbar.titleLabel.font = RobotoFont.regular(with: 14)
        toolbar.titleLabel.textColor = Color.grey.darken4
        toolbar.titleLabel.textAlignment = .left
        
        toolbar.detailLabel.textAlignment = .left
        toolbar.detailLabel.textColor = Color.grey.darken2
        
        card.toolbar = toolbar
        card.toolbarEdgeInsetsPreset = .square3
        card.toolbarEdgeInsets.bottom = 0
        card.toolbarEdgeInsets.right = 8
        
        card.contentView = contentLabel
        card.contentViewEdgeInsetsPreset = .wideRectangle3
        
        card.bottomBar = bottomBar
        card.bottomBarEdgeInsetsPreset = .wideRectangle2
    
        self.layout(card).horizontally(left: 10, right: 10).top(40)
        
        previewButton.addTarget(self, action: #selector(preview), for: .touchUpInside)
        copyButton.addTarget(self, action: #selector(copyURL), for: .touchUpInside)
        
        //小屏幕兼容
        if UIScreen.main.bounds.size.width <= 320 {
            card.contentViewEdgeInsetsPreset = .wideRectangle2
            card.bottomBarEdgeInsetsPreset = .wideRectangle1
            toolbar.titleLabel.font = RobotoFont.regular(with: 12)
            toolbar.detailLabel.font = RobotoFont.regular(with: 10)
            contentLabel.font = RobotoFont.regular(with: 10)
            noticeLabel.font = RobotoFont.regular(with: 10)
        }
    }
    
    @objc func copyURL(){
        if let urlStr = self.contentLabel.text{
            UIPasteboard.general.string = urlStr
            copyHandler?()
        }
    }
    @objc func preview(){
        
        if let urlStr = self.contentLabel.text?.urlEncoded(),
            let url = URL(string: urlStr){
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    var previewModel:PreviewModel?
    func bind(model:PreviewModel) {
        self.previewModel = model
        
        var fontSize:CGFloat = 14
        if UIScreen.main.bounds.size.width <= 320 {
            fontSize = 11
        }
        
        let serverUrl = URL(string: ServerManager.shared.currentAddress)!
        
        let attrStr = NSMutableAttributedString(string: "")
        attrStr.append(NSAttributedString(string: serverUrl.absoluteString, attributes: [
            NSAttributedStringKey.foregroundColor: Color.grey.darken4,
            NSAttributedStringKey.font : RobotoFont.regular(with: fontSize)
            ]))
        
        attrStr.append(NSAttributedString(string: "/\(Client.shared.key ?? "")", attributes: [
            NSAttributedStringKey.foregroundColor: Color.grey.darken3,
            NSAttributedStringKey.font : RobotoFont.regular(with: fontSize)
            ]))
        
        if let title = model.title {
            attrStr.append(NSAttributedString(string: "/\(title)", attributes: [
                NSAttributedStringKey.foregroundColor: Color.grey.darken1,
                NSAttributedStringKey.font : RobotoFont.regular(with: fontSize)
                ]))
            self.toolbar.title = title
        }
        if let body = model.body {
            attrStr.append(NSAttributedString(string: "/\(body)", attributes: [
                NSAttributedStringKey.foregroundColor: Color.grey.base,
                NSAttributedStringKey.font : RobotoFont.regular(with: fontSize)
                ]))
            if model.title == nil {
                self.toolbar.title = body
            }
            else{
                self.toolbar.detail = body
            }
        }
        self.contentLabel.attributedText = attrStr
        self.noticeLabel.text = model.notice
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

}
