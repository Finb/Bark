//
//  MessageSettingsViewController.swift
//  Bark
//
//  Created by huangfeng on 2020/5/28.
//  Copyright © 2020 Fin. All rights reserved.
//

import Material
import RxCocoa
import RxDataSources
import RxSwift
import UIKit
import UniformTypeIdentifiers

class MessageSettingsViewController: BaseViewController<MessageSettingsViewModel>, UIDocumentPickerDelegate {
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: .insetGrouped)
        tableView.separatorColor = BKColor.grey.lighten3
        tableView.backgroundColor = BKColor.background.primary
        tableView.register(LabelCell.self, forCellReuseIdentifier: "\(LabelCell.self)")
        tableView.register(iCloudStatusCell.self, forCellReuseIdentifier: "\(iCloudStatusCell.self)")
        tableView.register(ArchiveSettingCell.self, forCellReuseIdentifier: "\(ArchiveSettingCell.self)")
        tableView.register(DetailTextCell.self, forCellReuseIdentifier: "\(DetailTextCell.self)")
        tableView.register(MutableTextCell.self, forCellReuseIdentifier: "\(MutableTextCell.self)")
        tableView.register(SpacerCell.self, forCellReuseIdentifier: "\(SpacerCell.self)")
        tableView.register(DonateCell.self, forCellReuseIdentifier: "\(DonateCell.self)")
        
        tableView.estimatedSectionFooterHeight = 10
        tableView.estimatedSectionHeaderHeight = 10
        tableView.sectionFooterHeight = UITableView.automaticDimension
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        
        tableView.delegate = self
        return tableView
    }()

    private var headers: [String?] = []
    private var footers: [String?] = []
    
    override func makeUI() {
        self.title = NSLocalizedString("settings")
        
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    ///  导入、导出操作枚举
    enum BackupOrRestoreActionEnum {
        case export, `import`(data: Data)
    }
    
    /// UIDocumentPickerDelegate delegate
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        let canAccessingResource = url.startAccessingSecurityScopedResource()
        guard canAccessingResource else { return }
        
        let fileCoordinator = NSFileCoordinator()
        let err = NSErrorPointer(nilLiteral: ())
        fileCoordinator.coordinate(readingItemAt: url, error: err) { url in
            if let data = try? Data(contentsOf: url) {
                self.backupOrRestoreActionRelay.accept(.import(data: data))
            }
        }
        url.stopAccessingSecurityScopedResource()
    }
    
    /// 导入、导出事件
    let backupOrRestoreActionRelay = PublishRelay<BackupOrRestoreActionEnum>()
    
    /// 生成导入导出事件
    func getBackupOrRestoreAction() -> (Driver<Void>, Driver<Data>) {
        let backupOrRestoreAction = self.tableView.rx
//            .modelSelected(MessageSettingItem.self)
            .itemSelected
            .filter { indexPath in
                guard let viewModel: MessageSettingItem = try? self.tableView.rx.model(at: indexPath) else {
                    return false
                }
                if case MessageSettingItem.backup = viewModel {
                    return true
                }
                return false
            }
            .flatMapLatest { [weak self] indexPath in
                guard let strongSelf = self else {
                    return Observable<BackupOrRestoreActionEnum>.empty()
                }
            
                let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                alertController.addAction(UIAlertAction(title: NSLocalizedString("export"), style: .default, handler: { _ in
                    strongSelf.backupOrRestoreActionRelay.accept(.export)
                }))
            
                alertController.addAction(UIAlertAction(title: NSLocalizedString("import"), style: .default, handler: { [weak self] _ in
                    if #available(iOS 14.0, *) {
                        let supportedType: [UTType] = [UTType.json]
                        let pickerViewController = UIDocumentPickerViewController(forOpeningContentTypes: supportedType, asCopy: false)
                        pickerViewController.delegate = self
                        self?.present(pickerViewController, animated: true, completion: nil)
                    }
                }))
            
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: .cancel, handler: nil))
                if UIDevice.current.userInterfaceIdiom == .pad {
                    alertController.modalPresentationStyle = .popover
                    if let cell = strongSelf.tableView.cellForRow(at: indexPath) {
                        alertController.popoverPresentationController?.sourceView = strongSelf.tableView
                        alertController.popoverPresentationController?.sourceRect = cell.frame
                    }
                }
                strongSelf.present(alertController, animated: true, completion: nil)

                return strongSelf.backupOrRestoreActionRelay.asObservable()
            }
        
        let backupAction = backupOrRestoreAction
            .filter { action in
                if case .export = action { return true } else { return false }
            }
            .map { _ in () }
            .asDriver(onErrorDriveWith: .empty())
        
        let restoreAction = backupOrRestoreAction
            .compactMap { action in
                if case .import(let data) = action { return data } else { return nil }
            }
            .asDriver(onErrorDriveWith: .empty())
        
        return (backupAction, restoreAction)
    }
    
    override func bindViewModel() {
        let actions = getBackupOrRestoreAction()
        let output = viewModel.transform(
            input: MessageSettingsViewModel.Input(
                itemSelected: self.tableView.rx.modelSelected(MessageSettingItem.self).asDriver(),
                deviceToken: Client.shared.deviceToken.asDriver(),
                backupAction: actions.0,
                restoreAction: actions.1,
                viewDidAppear: self.rx.methodInvoked(#selector(viewDidAppear(_:)))
                    .map { _ in () },
                archiveSettingRelay: ArchiveSettingRelay.shared.isArchiveRelay
            )
        )
        
        let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<MessageSettingSection, MessageSettingItem>> { _, tableView, _, item -> UITableViewCell in
            switch item {
            case .label(let text):
                if let cell = tableView.dequeueReusableCell(withIdentifier: "\(LabelCell.self)") as? LabelCell {
                    cell.textLabel?.text = text
                    return cell
                }
            case .iCloudStatus:
                if let cell = tableView.dequeueReusableCell(withIdentifier: "\(iCloudStatusCell.self)") {
                    return cell
                }
            case .backup(let viewModel):
                if let cell = tableView.dequeueReusableCell(withIdentifier: "\(MutableTextCell.self)") as? MutableTextCell {
                    cell.textLabel?.textColor = BKColor.blue.darken1
                    cell.bindViewModel(model: viewModel)
                    return cell
                }
            case .archiveSetting(let viewModel):
                if let cell = tableView.dequeueReusableCell(withIdentifier: "\(ArchiveSettingCell.self)") as? ArchiveSettingCell {
                    cell.bindViewModel(model: viewModel)
                    return cell
                }
            case .detail(let title, let text, let textColor, _):
                if let cell = tableView.dequeueReusableCell(withIdentifier: "\(DetailTextCell.self)") as? DetailTextCell {
                    cell.textLabel?.text = title
                    cell.detailTextLabel?.text = text
                    cell.detailTextLabel?.textColor = textColor
                    return cell
                }
            case .deviceToken(let viewModel):
                if let cell = tableView.dequeueReusableCell(withIdentifier: "\(MutableTextCell.self)") as? MutableTextCell {
                    cell.bindViewModel(model: viewModel)
                    return cell
                }
            case .spacer(let height, let color):
                if let cell = tableView.dequeueReusableCell(withIdentifier: "\(SpacerCell.self)") as? SpacerCell {
                    cell.height = height
                    cell.backgroundColor = color
                    return cell
                }
            case .donate(let title, let productId):
                if let cell = tableView.dequeueReusableCell(withIdentifier: "\(DonateCell.self)") as? DonateCell {
                    cell.title = title
                    cell.productId = productId
                    return cell
                }
            }
            
            return UITableViewCell()
        }
        
        // 设置项的 header、footer
        output.settings
            .drive(onNext: { [weak self] settings in
                self?.headers.removeAll()
                self?.footers.removeAll()
                for section in settings {
                    self?.headers.append(section.model.header)
                    self?.footers.append(section.model.footer)
                }
            })
            .disposed(by: rx.disposeBag)
        // 设置项数据源
        output.settings
            .drive(tableView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)
     
        // 打开 URL 操作
        output.openUrl.drive { [weak self] url in
            self?.navigationController?.present(BarkSFSafariViewController(url: url), animated: true, completion: nil)
        }.disposed(by: rx.disposeBag)
        
        // 复制 deviceToken 操作
        output.copyDeviceToken.drive { [weak self] deviceToken in
            UIPasteboard.general.string = deviceToken
            self?.showSnackbar(text: NSLocalizedString("Copy"))
        }.disposed(by: rx.disposeBag)
        
        // 导出数据
        output.exportData.drive { [weak self] data in
            
            let fileManager = FileManager.default
            let tempDirectoryURL = fileManager.temporaryDirectory
            let fileName = "bark_messages_\(Date().formatString(format: "yyyy_MM_dd_HH_mm_ss")).json"
            let linkURL = tempDirectoryURL.appendingPathComponent(fileName)
            
            do {
                // 清空temp文件夹
                try fileManager
                    .contentsOfDirectory(at: tempDirectoryURL, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants)
                    .forEach { file in
                        try? fileManager.removeItem(atPath: file.path)
                    }
                // 写入临时文件
                try data.write(to: linkURL)
            } catch {
                // Hope nothing happens
            }
            
            let activityController = UIActivityViewController(activityItems: [linkURL], applicationActivities: nil)
            if UIDevice.current.userInterfaceIdiom == .pad {
                activityController.popoverPresentationController?.sourceView = self?.view
                activityController.popoverPresentationController?.sourceRect = self?.view.frame ?? .zero
            }
            self?.navigationController?.present(activityController, animated: true, completion: nil)
            
        }.disposed(by: rx.disposeBag)
    }
}

extension MessageSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard self.headers.count > section, let header = self.headers[section] else { return UIView() }
        
        let headerView = SettingSectionHeader()
        headerView.titleLabel.text = header
        return headerView
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard self.footers.count > section, let footer = self.footers[section] else { return UIView() }
        
        let footerView = SettingSectionFooter()
        footerView.titleLabel.text = footer
        return footerView
    }
}
