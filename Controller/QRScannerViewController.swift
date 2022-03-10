//
//  QRScannerViewController.swift
//  Bark
//
//  Created by huangfeng on 2022/3/10.
//  Copyright © 2022 Fin. All rights reserved.
//

import MercariQRScanner
import RxCocoa
import RxSwift
import UIKit

class QRScannerViewController: UIViewController {
    var scannerDidSuccess: Observable<String> {
        return self.rx.methodInvoked(#selector(didSeccess(code:))).map { a in
            try castOrThrow(String.self, a[0])
        }
    }

    let closeButton: UIButton = {
        let closeButton = UIButton(type: .custom)
        closeButton.setImage(UIImage(named: "baseline_close_white_48pt"), for: .normal)
        closeButton.tintColor = UIColor.white
        closeButton.backgroundColor = UIColor(white: 0, alpha: 0.2)
        closeButton.layer.cornerRadius = 40
        closeButton.clipsToBounds = true
        return closeButton
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black

        let qrScannerView = QRScannerView(frame: view.bounds)
        qrScannerView.configure(delegate: self)
        view.addSubview(qrScannerView)

        view.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-120)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(80)
        }
        closeButton.rx.tap.subscribe { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        } onError: { _ in }.disposed(by: rx.disposeBag)

        qrScannerView.startRunning()
    }
}

extension QRScannerViewController: QRScannerViewDelegate {
    func qrScannerView(_ qrScannerView: QRScannerView, didFailure error: QRScannerError) {
        self.showSnackbar(text: error.rawString())
    }

    func qrScannerView(_ qrScannerView: QRScannerView, didSuccess code: String) {
        self.didSeccess(code: code)
        self.dismiss(animated: true, completion: nil)
    }

    @objc private func didSeccess(code: String) {}
}
