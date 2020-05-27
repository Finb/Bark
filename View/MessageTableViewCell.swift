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
        label.font = RobotoFont.regular(with: 16)
        label.textColor = Color.darkText.primary
        label.numberOfLines = 0
        return label
    }()
    let bodyLabel: UILabel = {
        let label = UILabel()
        label.font = RobotoFont.regular(with: 14)
        label.textColor = Color.darkText.secondary
        label.numberOfLines = 0
        return label
    }()
    
    let urlLabel: UILabel = {
        let label = UILabel()
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
            make.left.equalTo(bodyLabel)
            make.top.equalTo(bodyLabel.snp.bottom).offset(6)
        }
        if (message?.url?.count ?? 0) > 0{
            dateLabel.snp.remakeConstraints { (make) in
                make.left.equalTo(urlLabel)
                make.top.equalTo(urlLabel.snp.bottom).offset(6)
            }
        }
        else{
            dateLabel.snp.remakeConstraints { (make) in
                make.left.equalTo(bodyLabel)
                make.top.equalTo(bodyLabel.snp.bottom).offset(6)
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
            self.titleLabel.text = message?.title
            self.bodyLabel.text = message?.body
            self.urlLabel.text = message?.url
            self.dateLabel.text = (message?.createDate ?? Date()).agoFormatString()
            layoutView()
            
        }
    }
    
}
