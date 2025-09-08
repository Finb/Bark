//
//  InsetView.swift
//  Bark
//
//  Created by huangfeng on 9/8/25.
//  Copyright © 2025 Fin. All rights reserved.
//

import UIKit

class InsetView: UIView {
    init(subView: UIView, insets: UIEdgeInsets) {
        super.init(frame: .zero)
        self.addSubview(subView)
        subView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(insets)
        }
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
