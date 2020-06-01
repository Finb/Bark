//
//  MessageTableViewCell.swift
//  Bark
//
//  Created by huangfeng on 2020/5/26.
//  Copyright © 2020 Fin. All rights reserved.
//

import UIKit
import Material
class MessageTableViewCell: UITableViewCell {
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = RobotoFont.medium(with: 16)
        label.textColor = Color.darkText.primary
        label.numberOfLines = 0
        return label
    }()
    let bodyLabel: UILabel = {
        let label = UILabel()
        label.font = RobotoFont.regular(with: 14)
        label.textColor = Color.darkText.primary
        label.numberOfLines = 0
        return label
    }()
    
    let urlLabel: UILabel = {
        let label = BKLabel()
        label.hitTestSlop = UIEdgeInsets(top: -20, left: -20, bottom: -20, right: -20)
        label.isUserInteractionEnabled = true
        label.font = RobotoFont.regular(with: 14)
        label.textColor = Color.blue.darken1
        label.numberOfLines = 0
        return label
    }()
    
    let dateLabel: UILabel = {
        let label = UILabel()
        label.font = RobotoFont.medium(with: 11)
        label.textColor = Color.darkText.others
        return label
    }()
    let separatorLine:UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = Color.grey.lighten5
        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        
        self.backgroundColor = Color.white
        
        addSubview(titleLabel)
        addSubview(bodyLabel)
        addSubview(urlLabel)
        addSubview(dateLabel)
        addSubview(separatorLine)
        
        self.urlLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(urlTap)))
    }
    func layoutView(){
        titleLabel.snp.remakeConstraints { (make) in
            make.left.equalTo(12)
            make.top.equalTo(12)
            make.right.equalTo(-12)
        }
        if (message?.title?.count ?? 0) > 0 {
            bodyLabel.snp.remakeConstraints { (make) in
                make.left.right.equalTo(titleLabel)
                make.top.equalTo(titleLabel.snp.bottom).offset(6)
            }
        }
        else{
            bodyLabel.snp.remakeConstraints { (make) in
                make.left.equalTo(12)
                make.top.equalTo(12)
                make.right.equalTo(-12)
            }
        }
        
        urlLabel.snp.makeConstraints { (make) in
            make.left.right.equalTo(bodyLabel)
            make.top.equalTo(bodyLabel.snp.bottom).offset(12)
        }
        if (message?.url?.count ?? 0) > 0{
            urlLabel.isUserInteractionEnabled = true
            dateLabel.snp.remakeConstraints { (make) in
                make.left.equalTo(urlLabel)
                make.top.equalTo(urlLabel.snp.bottom).offset(12)
            }
        }
        else{
            urlLabel.isUserInteractionEnabled = false
            dateLabel.snp.remakeConstraints { (make) in
                make.left.equalTo(bodyLabel)
                make.top.equalTo(bodyLabel.snp.bottom).offset(12)
            }
        }

        
        separatorLine.snp.remakeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(dateLabel.snp.bottom).offset(12)
            make.height.equalTo(8)
        }
        
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    var message:Message? {
        didSet{
            setupTextValue(label: self.titleLabel, text: message?.title)
            setupTextValue(label: self.bodyLabel, text: message?.body)
            
            self.urlLabel.text = message?.url
            self.dateLabel.text = (message?.createDate ?? Date()).agoFormatString()
            layoutView()
            
        }
    }
    func setupTextValue(label:UILabel, text:String?){
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 3
        
        let attrStr = NSAttributedString(string: text ?? "",
                                         attributes: [
                                            .paragraphStyle: style,
                                            .font: label.font!,
                                            .foregroundColor: label.textColor!])
        label.attributedText = attrStr
    }
    
    @objc func urlTap(){
        if let urlStr = self.message?.url, let url = URL(string: urlStr){
            if ["http","https"].contains(url.scheme?.lowercased() ?? ""){
                  Client.shared.currentNavigationController?.present(BarkSFSafariViewController(url: url), animated: true, completion: nil)
              }
              else{
                  UIApplication.shared.open(url, options: [:], completionHandler: nil)
              }
        }
    }
}
