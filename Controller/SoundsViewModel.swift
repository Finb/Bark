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
    struct Input {
        var soundSelected: Driver<SoundItem>
    }

    struct Output {
        var audios: Observable<[SectionModel<String, SoundItem>]>
        var copyNameAction: Driver<String>
        var playAction: Driver<CFURL>
        var pickerFile: Driver<Void>
    }

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
                if file.hasSuffix(suffix) {
                    return URL(fileURLWithPath: directory).appendingPathComponent(file)
                }
                return nil
            }
        } catch {
            return []
        }
    }

    func transform(input: Input) -> Output {
        let defaultSounds = getSounds(
            urls: Bundle.main.urls(forResourcesWithExtension: "caf", subdirectory: nil) ?? []
        )

        let customSounds: [SoundItem] = {
            guard let soundsDirectoryUrl = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first?.appending("/Sounds") else {
                return [.addSound]
            }
            return getSounds(
                urls: getFilesInDirectory(directory: soundsDirectoryUrl, suffix: "caf")
            ) + [.addSound]
        }()

        let copyAction = Driver.merge(
            (defaultSounds + customSounds).compactMap { item in
                if case SoundItem.sound(let model) = item {
                    return model.copyNameAction.asDriver(onErrorDriveWith: .empty())
                }
                return nil
            }
        ).asDriver()

        return Output(
            audios: Observable.just([
                SectionModel(model: "customSounds", items: customSounds),
                SectionModel(model: "defaultSounds", items: defaultSounds)
            ]),
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
                })
    }
}
