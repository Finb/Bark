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
	// 当前正在播放的音频资源ID
	var currentSoundID: SystemSoundID = 0
	// 当前正在播放的音频文件ULRL
	var playingAudio: CFURL?

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
			/// 先结束正在播放的音频
			AudioServicesDisposeSystemSoundID(self.currentSoundID)
			/// 如果重复点击了当前音频，结束播放
			if self.playingAudio == url{
				self.playingAudio = nil
				self.currentSoundID = 0
				return
			}
			self.playingAudio = url
			AudioServicesCreateSystemSoundID(url, &self.currentSoundID)
			AudioServicesPlaySystemSoundWithCompletion(self.currentSoundID) {
				/// 判断是否是当前播放的音频，防止逻辑错误
				if self.playingAudio == url {
					AudioServicesDisposeSystemSoundID(self.currentSoundID)
					self.playingAudio = nil
					self.currentSoundID = 0
				}
			}
        }).disposed(by: rx.disposeBag)
        
        output.pickerFile.drive(onNext: { [unowned self] _ in
            self.pickerSoundFile()
        }).disposed(by: rx.disposeBag)
    }
}

extension SoundsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard section == 0 else {
            return 0
        }
        return NSLocalizedString("uploadSoundNoticeFullText").count <= 30 ? 50 : 60
    }
    
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

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section == 0 else {
            return nil
        }
        let view = UIView()
        
        let fullText = NSLocalizedString("uploadSoundNoticeFullText")
        let highlightText = NSLocalizedString("uploadSoundNoticeHighlightText")
        let attrStr = NSMutableAttributedString(
            string: fullText,
            attributes: [
                NSAttributedString.Key.foregroundColor: BKColor.grey.darken3,
                NSAttributedString.Key.font: UIFont.preferredFont(ofSize: 14)
            ]
        )
        attrStr.setAttributes([
            NSAttributedString.Key.foregroundColor: BKColor.lightBlue.darken3,
            NSAttributedString.Key.font: UIFont.preferredFont(ofSize: 14)
        ], range: (fullText as NSString).range(of: highlightText))
        
        let label = UILabel()
        label.attributedText = attrStr
        label.numberOfLines = 0
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.left.equalTo(12)
            make.right.equalTo(-12)
            make.top.equalTo(12)
        }
        
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer())
        label.gestureRecognizers?.first?.rx.event.subscribe(onNext: { _ in
            UIApplication.shared.open(URL(string: "https://convertio.co/mp3-caf/")!)
        }).disposed(by: label.rx.disposeBag)
        
        return view
    }
}

extension SoundsViewController: UIDocumentPickerDelegate {
    /// 选择 caf 文件
    func pickerSoundFile() {
        if #available(iOS 14.0, *) {
            /// 直接修改文件扩展为 .audio iOS 支持的音频格式
            let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio])
            documentPicker.delegate = self
            documentPicker.allowsMultipleSelection = false
            documentPicker.modalPresentationStyle = .pageSheet
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
            // 检查文件扩展名是否为 caf
            if url.pathExtension.lowercased() == "caf" {
                // 如果是 caf 文件，直接导入
                self.importSoundActionRelay.accept(url)
            } else {
                // 如果不是 caf 文件，先转换为 caf 格式
                convertAudioToCAF(inputURL: url) { url in
                    if let url {
                        // 转换成功后导入
                        self.importSoundActionRelay.accept(url)
                    }
                }
            }
        }
        url.stopAccessingSecurityScopedResource()
    }
    
    /// 将音频文件转换为 CAF 格式
    /// - Parameters:
    ///   - inputURL: 输入音频文件的 URL
    ///   - completion: 转换完成后的回调，返回转换后的 CAF 文件 URL，如果转换失败则返回 nil
    func convertAudioToCAF(inputURL: URL, completion: @escaping (URL?) -> Void) {
        let fileName = inputURL.deletingPathExtension().lastPathComponent
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).caf")

        do {
            if FileManager.default.fileExists(atPath: outputURL.path) {
                try FileManager.default.removeItem(at: outputURL)
            }

            let asset = AVAsset(url: inputURL)
            guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
                completion(nil)
                return
            }

            let maxDuration = CMTime(seconds: 29.9, preferredTimescale: 600)
            if asset.duration > maxDuration {
                exportSession.timeRange = CMTimeRange(start: .zero, duration: maxDuration)
            }

            exportSession.outputFileType = .caf
            exportSession.outputURL = outputURL

            exportSession.exportAsynchronously {
                DispatchQueue.main.async {
                    completion(exportSession.status == .completed ? outputURL : nil)
                }
            }

        } catch {
            completion(nil)
        }
    }
}
