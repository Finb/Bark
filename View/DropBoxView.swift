//
//  DropBoxView.swift
//  Bark
//
//  Created by huangfeng on 2023/2/2.
//  Copyright © 2023 Fin. All rights reserved.
//

import DropDown
import RxCocoa
import RxSwift
import UIKit

class DropBoxView: UIView {
    let valueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(ofSize: 14)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = BKColor.grey.darken3
        return label
    }()

    let dropIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "baseline_keyboard_arrow_down_black_24pt")?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = BKColor.grey.lighten2
        return imageView
    }()

    var isSelecting: Bool = true {
        didSet {
            UIView.animate(withDuration: 0.3) {
                if self.isSelecting {
                    self.borderColor = BKColor.blue.darken5
                    self.shadowColor = BKColor.blue.darken5
                    self.layer.shadowOpacity = 0.3
                } else {
                    self.borderColor = BKColor.grey.lighten2
                    self.shadowColor = BKColor.grey.lighten2
                    self.layer.shadowOpacity = 0
                }
            }
        }
    }

    var values: [String] {
        didSet {
            self.currentValue = values.first
        }
    }

    var currentValue: String? {
        didSet {
            self.valueLabel.text = currentValue
            self.currentValueSubject.onNext(self.currentValue)
        }
    }

    fileprivate let currentValueSubject = PublishSubject<String?>()

    init(values: [String]) {
        self.values = values
        super.init(frame: CGRect.zero)
        self.backgroundColor = BKColor.white

        self.borderColor = BKColor.grey.lighten2
        self.borderWidthPreset = .border2
        self.cornerRadiusPreset = .cornerRadius3
        self.shadowColor = BKColor.grey.lighten2
        self.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.layer.shadowRadius = 2
        self.layer.shadowOpacity = 0

        addSubview(valueLabel)
        addSubview(dropIconView)

        self.dropIconView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalTo(-6)
        }
        self.valueLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(16)
        }

        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap)))

        defer {
            self.currentValue = self.values.first
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func tap() {
        let dropDown = DropDown(anchorView: self)
        dropDown.cellNib = UINib(nibName: "BKDropDownCell", bundle: Bundle(for: BKDropDownCell.self))
        dropDown.cellHeight = 50
        dropDown.cornerRadius = 10
        dropDown.clipsToBounds = true
        dropDown.bottomOffset = CGPoint(x: 0, y: 50)

        dropDown.dataSource = self.values

        dropDown.selectionAction = { [weak self] _, str in
            self?.currentValue = str
            self?.isSelecting = false
        }
        dropDown.cancelAction = { [weak self] in
            self?.isSelecting = false
        }
        self.isSelecting = true
        dropDown.show()
    }
}

extension Reactive where Base: DropBoxView {
    var currentValueChanged: ControlEvent<String?> {
        let source = base.currentValueSubject.asObservable()
        return ControlEvent(events: source)
    }
}
