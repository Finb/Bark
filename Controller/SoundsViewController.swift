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
        let tableView = UITableView(frame: CGRect.zero, style: .insetGrouped)
        tableView.backgroundColor = BKColor.background.primary
        tableView.register(SoundCell.self, forCellReuseIdentifier: "\(SoundCell.self)")
        tableView.register(AddSoundCell.self, forCellReuseIdentifier: "\(AddSoundCell.self)")
        return tableView
    }()
    
    // 上传铃声文件事件序列
    let importSoundActionRelay = PublishRelay<URL>()

    override func makeUI() {
        self.title = NSLocalizedString("notificationSound")

        self.view.addSubview(self.tableView)
        self.tableView.delegate = self
        self.tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func bindViewModel() {
        let output = viewModel.transform(
            input: SoundsViewModel.Input(
                soundSelected: self.tableView.rx.modelSelected(SoundItem.self).asDriver(),
                importSound: self.importSoundActionRelay.asDriver(onErrorDriveWith: .empty()),
                soundDeleted: self.tableView.rx.modelDeleted(SoundItem.self).asDriver()
            )
        )

        let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, SoundItem>> { _, tableView, _, item -> UITableViewCell in
            switch item {
            case .sound(let model):
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(SoundCell.self)") as? SoundCell else {
                    return UITableViewCell()
                }
                cell.bindViewModel(model: model)
                return cell
            case .addSound:
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(AddSoundCell.self)") else {
                    return UITableViewCell()
                }
                return cell
            }
            
        } titleForHeaderInSection: { dataSource, section in
            return dataSource[section].model
        } canEditRowAtIndexPath: { dataSource, indexPath in
            guard indexPath.section == 0 else {
                return false
            }
            guard case SoundItem.sound = dataSource[indexPath.section].items[indexPath.row] else {
                return false
            }
            return true
        }

        output.audios
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)

        output.copyNameAction.drive(onNext: { [unowned self] name in
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
        
        output.pickerFile.drive(onNext: { [unowned self] _ in
            self.pickerSoundFile()
        }).disposed(by: rx.disposeBag)
    }
}

extension SoundsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionTitle = tableView.dataSource?.tableView?(tableView, titleForHeaderInSection: section) ?? ""
        
        let view = UIView()
        
        let label = UILabel()
        label.text = NSLocalizedString(sectionTitle)
        label.fontSize = 14
        label.textColor = BKColor.grey.darken3
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.left.equalTo(12)
            make.centerY.equalToSuperview()
        }
        
        return view
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
}

extension SoundsViewController: UIDocumentPickerDelegate {
    /// 选择 caf 文件
    func pickerSoundFile() {
        if #available(iOS 14.0, *) {
            let types = UTType.types(tag: "caf",
                                     tagClass: UTTagClass.filenameExtension,
                                     conformingTo: nil)
            let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: types)
            documentPicker.delegate = self
            documentPicker.allowsMultipleSelection = false
            documentPicker.modalPresentationStyle = .formSheet
            self.present(documentPicker, animated: true, completion: nil)
        } else {
            self.showSnackbar(text: "Requires iOS 14")
        }
    }
    
    // 文件选择完成回调
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        let canAccessingResource = url.startAccessingSecurityScopedResource()
        guard canAccessingResource else { return }
        
        let fileCoordinator = NSFileCoordinator()
        let err = NSErrorPointer(nilLiteral: ())
        fileCoordinator.coordinate(readingItemAt: url, error: err) { url in
            self.importSoundActionRelay.accept(url)
        }
        url.stopAccessingSecurityScopedResource()
    }
}
