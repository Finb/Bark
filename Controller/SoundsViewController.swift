//
//  SoundsViewController.swift
//  Bark
//
//  Created by huangfeng on 2020/9/14.
//  Copyright © 2020 Fin. All rights reserved.
//

import AVKit
import Material
import UIKit

import NSObject_Rx
import RxCocoa
import RxDataSources
import RxSwift

class SoundsViewController: BaseViewController<SoundsViewModel> {
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = BKColor.background.primary
        tableView.register(SoundCell.self, forCellReuseIdentifier: "\(SoundCell.self)")
        return tableView
    }()

    override func makeUI() {
        self.title = NSLocalizedString("notificationSound")

        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.tableView.tableHeaderView = {
            let header = UILabel()
            header.fontSize = 12
            header.text = "    \(NSLocalizedString("previewSound"))"
            header.textColor = BKColor.grey.darken1
            header.frame = CGRect(x: 0, y: 0, width: 0, height: 40)
            return header
        }()
    }

    override func bindViewModel() {
        let output = viewModel.transform(
            input: SoundsViewModel.Input(soundSelected: self.tableView.rx
                .modelSelected(SoundCellViewModel.self)
                .asDriver()))

        let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, SoundCellViewModel>> { _, tableView, _, item -> UITableViewCell in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(SoundCell.self)") as? SoundCell else {
                return UITableViewCell()
            }
            cell.bindViewModel(model: item)
            return cell
        }

        output.audios
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)

        output.copyNameAction.drive(onNext: { name in
            UIPasteboard.general.string = name.trimmingCharacters(in: .whitespacesAndNewlines)
            self.navigationController?.showSnackbar(text: NSLocalizedString("Copy"))
        }).disposed(by: rx.disposeBag)

        output.playAction.drive(onNext: { url in
            var soundID: SystemSoundID = 0
            AudioServicesCreateSystemSoundID(url, &soundID)
            AudioServicesPlaySystemSoundWithCompletion(soundID) {
                AudioServicesDisposeSystemSoundID(soundID)
            }
        }).disposed(by: rx.disposeBag)
    }
}
