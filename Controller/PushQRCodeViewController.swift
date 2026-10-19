//
//  PushQRCodeViewController.swift
//  Bark
//
//  Created by xic on 2026/10/16.
//  Copyright © 2026 Fin. All rights reserved.
//

import NSObject_Rx
import RxSwift
import SnapKit
import UIKit

/// 展示推送 URL / Key 的二维码，方便其他设备（如运行短信转发器的备用机）
/// 用系统相机扫码后复制粘贴完成配置。纯展示页面，参考 QRScannerViewController 不写 ViewModel。
class PushQRCodeViewController: UIViewController {
    private enum Content: Int {
        case url = 0
        case key

        var text: String {
            let server = ServerManager.shared.currentServer
            switch self {
            case .url: return server.addressAndKey
            case .key: return server.key
            }
        }
    }

    private var content: Content = .url {
        didSet { reloadContent() }
    }

    private let closeButton: BKButton = {
        let closeButton = BKButton()
        closeButton.setImage(UIImage(named: "baseline_keyboard_arrow_down_black_24pt")?.withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        closeButton.hitTestSlop = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        closeButton.tintColor = BKColor.grey.darken4
        closeButton.accessibilityLabel = "close".localized
        return closeButton
    }()

    // 分段标题与 HomeExampleSegmentedControl 的 GET/POST/JSON 一样不本地化
    private let segmentedControl = UISegmentedControl(items: ["URL", "Key"])

    // 二维码固定在白色容器内，保证深色模式下依然可扫
    private let qrContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 14
        view.clipsToBounds = true
        return view
    }()

    private let qrImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isAccessibilityElement = false
        return imageView
    }()

    private let textLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: UIFont.monospacedSystemFont(ofSize: 12, weight: .regular))
        label.textColor = .label
        label.numberOfLines = 0
        label.lineBreakMode = .byCharWrapping
        label.textAlignment = .center
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "showQRCode".localized
        view.backgroundColor = BKColor.background.primary

        navigationItem.setRightBarButtonItem(item: UIBarButtonItem(customView: closeButton))

        segmentedControl.selectedSegmentIndex = Content.url.rawValue
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)

        qrContainer.addSubview(qrImageView)

        [segmentedControl, qrContainer, textLabel].forEach(view.addSubview)

        segmentedControl.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(24)
            make.centerX.equalToSuperview()
        }
        qrContainer.snp.makeConstraints { make in
            make.top.equalTo(segmentedControl.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(240)
        }
        qrImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
        textLabel.snp.makeConstraints { make in
            make.top.equalTo(qrContainer.snp.bottom).offset(16)
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().offset(-24)
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualTo(480)
        }

        closeButton.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        }).disposed(by: rx.disposeBag)

        reloadContent()
    }

    @objc private func segmentChanged() {
        content = Content(rawValue: segmentedControl.selectedSegmentIndex) ?? .url
    }

    private func reloadContent() {
        let text = content.text
        qrImageView.image = QRCodeGenerator.image(for: text, size: 512)
        textLabel.text = text
    }
}
