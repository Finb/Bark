//
//  SoundsViewModel.swift
//  Bark
//
//  Created by huangfeng on 2020/11/17.
//  Copyright © 2020 Fin. All rights reserved.
//

import AVKit
import Foundation
import RxCocoa
import RxDataSources
import RxSwift

enum SoundItem {
    case sound(model: SoundCellViewModel)
    case addSound
}

class SoundsViewModel: ViewModel, ViewModelType {
    /// 依赖
    struct Dependencies {
        /// 用于保存铃声文件
        let soundFileStorage: SoundFileStorageProtocol
    }

    private let dependencies: Dependencies
    init(dependencies: Dependencies = Dependencies(soundFileStorage: SoundFileStorage())) {
        self.dependencies = dependencies
    }

    struct Input {
        /// 铃声列表点击
        var soundSelected: Driver<SoundItem>
        /// 铃声导入
        var importSound: Driver<URL>
        /// 删除铃声
        var soundDeleted: Driver<SoundItem>
    }

    struct Output {
        /// 铃声数据源
        var audios: Observable<[SectionModel<String, SoundItem>]>
        /// 复制铃声名称
        var copyNameAction: Driver<String>
        /// 播放铃声
        var playAction: Driver<CFURL>
        /// 打开文件选择器选择铃声文件
        var pickerFile: Driver<Void>
    }

    /// 将铃声 URL 转换成 SoundItem
    func getSounds(urls: [URL]) -> [SoundItem] {
        let urls = urls.sorted { u1, u2 -> Bool in
            u1.lastPathComponent.localizedStandardCompare(u2.lastPathComponent) == ComparisonResult.orderedAscending
        }
        return urls
            .map { AVURLAsset(url: $0) }
            .map { SoundCellViewModel(model: $0) }
            .map { SoundItem.sound(model: $0) }
    }

    /// 返回指定文件夹，指定后缀的文件列表数组
    func getFilesInDirectory(directory: String, suffix: String) -> [URL] {
        let fileManager = FileManager.default
        do {
            let files = try fileManager.contentsOfDirectory(atPath: directory)
            return files.compactMap { file -> URL? in
                if file.hasSuffix(suffix), !file.hasPrefix(kBarkSoundPrefix) {
                    // 不要包含 kBarkSoundPrefix 开头的，这些是为了 call=1 合成的 30s 长铃声,不算用户上传的
                    return URL(fileURLWithPath: directory).appendingPathComponent(file)
                }
                return nil
            }
        } catch {
            return []
        }
    }

    func transform(input: Input) -> Output {
        // 保存文件
        input
            .importSound
            .drive { [unowned self] url in
                self.dependencies.soundFileStorage.saveSound(url: url)
            }
            .disposed(by: rx.disposeBag)
        
        // 删除铃声
        input.soundDeleted.drive(onNext: { item in
            guard case SoundItem.sound(let model) = item else {
                return
            }
            self.dependencies.soundFileStorage.deleteSound(name: model.model.url.lastPathComponent)
        }).disposed(by: rx.disposeBag)
        
        // 铃声列表有更新
        let soundsListUpdated = Observable.merge(
            // 刚进页面
            Observable.just(()),
            // 上传了新铃声
            input.importSound.map { _ in () }.asObservable(),
            // 删除了铃声
            input.soundDeleted.map { _ in () }.asObservable()
        ).share(replay: 1)
        
        // 所有铃声列表，包含自定义铃声和默认铃声
        let sounds: Observable<([SoundItem], [SoundItem])> = soundsListUpdated.map { [weak self] _ in
            guard let self else { return ([], []) }
            
            let defaultSounds = self.getSounds(
                urls: Bundle.main.urls(forResourcesWithExtension: "caf", subdirectory: nil) ?? []
            )

            let customSounds: [SoundItem] = {
                guard let soundsDirectoryUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.bark")?.appendingPathComponent("Library/Sounds").path else {
                    return [.addSound]
                }
                return self.getSounds(
                    urls: self.getFilesInDirectory(directory: soundsDirectoryUrl, suffix: "caf")
                ) + [.addSound]
            }()
            return (customSounds, defaultSounds)
        }.share(replay: 1)
        
        // 用于 RxDataSource 的数据源
        let dataSource = sounds.map { sounds in
            return [
                SectionModel(model: "customSounds", items: sounds.0),
                SectionModel(model: "defaultSounds", items: sounds.1)
            ]
        }
        
        // 铃声列表点击复制按钮事件
        let copyAction = sounds.flatMapLatest { sounds in
            let observables = (sounds.0 + sounds.1).compactMap { item in
                if case SoundItem.sound(let model) = item {
                    return model
                }
                return nil
            }.map { model in
                return model.copyNameAction.asObservable()
            }
            return Observable.merge(observables)
        }.asDriver(onErrorDriveWith: .empty())

        return Output(
            audios: dataSource,
            copyNameAction: copyAction,
            playAction: input.soundSelected
                .compactMap { item in
                    if case SoundItem.sound(let model) = item {
                        return model
                    }
                    return nil
                }
                .map { $0.model.url as CFURL },
            pickerFile: input.soundSelected
                .compactMap { item in
                    if case SoundItem.addSound = item {
                        return ()
                    }
                    return nil
                }
        )
    }
}

/// 保存铃声文件协议
protocol SoundFileStorageProtocol {
    func saveSound(url: URL)
    func deleteSound(name: String)
}

/// 用于将铃声文件保存在  /Library/Sounds 文件夹中
class SoundFileStorage: SoundFileStorageProtocol {
    let fileManager: FileManager
    init() {
        fileManager = FileManager()
    }

    /// 将指定文件保存在 Library/Sound，如果存在则覆盖
    func saveSound(url: URL) {
        // 保存到Sounds文件夹
        guard let soundsDirectoryUrl = getSoundsDirectory() else {
            return
        }
        let soundUrl = soundsDirectoryUrl.appendingPathComponent(url.lastPathComponent)
        try? fileManager.copyItem(at: url, to: soundUrl)
    }

    func deleteSound(name: String) {
        guard let soundsDirectoryUrl = getSoundsDirectory() else {
            return
        }
        let soundUrl = soundsDirectoryUrl.appendingPathComponent(name)
        let callSoundUrl = soundsDirectoryUrl.appendingPathComponent("\(kBarkSoundPrefix).\(name)")
        // 删除 sounds 目录铃声文件
        try? fileManager.removeItem(at: soundUrl)
        // 删除 call=1 生成的铃声文件
        try? fileManager.removeItem(at: callSoundUrl)
    }

    /// 获取 Library 目录下的 Sounds 文件夹
    /// 如果不存在就创建
    private func getSoundsDirectory() -> URL? {
        guard let soundsDirectoryUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.bark")?.appendingPathComponent("Library/Sounds") else {
            return nil
        }
        if !fileManager.fileExists(atPath: soundsDirectoryUrl.path) {
            try? fileManager.createDirectory(atPath: soundsDirectoryUrl.path, withIntermediateDirectories: true, attributes: nil)
        }
        return URL(fileURLWithPath: soundsDirectoryUrl.path)
    }
}
