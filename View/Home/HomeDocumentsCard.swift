//
//  HomeDocumentsCard.swift
//  Bark
//
//  Created by huangfeng on 8/25/26.
//  Copyright © 2026 Fin. All rights reserved.
//

import UIKit

final class HomeDocumentsCard: GlassView {
    let parameterButton: HomeFlatButton = {
        let button = HomeFlatButton()
        button.title = "pushParameters".localized
        button.image = UIImage(systemName: "book.closed")
        return button
    }()
    let faqButton: HomeFlatButton = {
        let button = HomeFlatButton()
        button.title = "faq".localized
        button.image = UIImage(systemName: "questionmark.circle")
        return button
    }()
    private let sectionLabel: UILabel = {
        let label = UILabel()
        label.text = "documentsAndExamples".localized
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "documentsAndExamplesDetail".localized
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        return label
    }()
    private let actions: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.distribution = .fillEqually
        return stack
    }()

    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        return stack
    }()

    override init() {
        super.init()
        actions.addArrangedSubview(parameterButton)
        actions.addArrangedSubview(faqButton)

        contentStack.addArrangedSubview(sectionLabel)
        contentStack.addArrangedSubview(descriptionLabel)
        contentStack.addArrangedSubview(actions)
        contentStack.setCustomSpacing(6, after: sectionLabel)
        contentView.addSubview(contentStack)

        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
        actions.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
