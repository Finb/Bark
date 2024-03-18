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

class SoundsViewModel: ViewModel, ViewModelType {
    struct Input {
        var soundSelected: Driver<SoundCellViewModel>
    }

    struct Output {
        var audios: Observable<[SectionModel<String, SoundCellViewModel>]>
        var copyNameAction: Driver<String>
        var playAction: Driver<CFURL>
    }

    func getSounds(urls: [URL]) -> [SoundCellViewModel] {
        let urls = urls.sorted { u1, u2 -> Bool in
            u1.lastPathComponent.localizedStandardCompare(u2.lastPathComponent) == ComparisonResult.orderedAscending
        }
        return urls
            .map { AVURLAsset(url: $0) }
            .map { SoundCellViewModel(model: $0) }
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

        let customSounds: [SoundCellViewModel] = {
            guard let soundsDirectoryUrl = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first?.appending("/Sounds") else {
                return []
            }
            return getSounds(
                urls: getFilesInDirectory(directory: soundsDirectoryUrl, suffix: "caf")
            )
        }()

        let copyAction = Driver.merge(
            (defaultSounds + customSounds).map { $0.copyNameAction.asDriver(onErrorDriveWith: .empty()) }
        ).asDriver()

        return Output(
            audios: Observable.just([
                SectionModel(model: "customSounds", items: customSounds),
                SectionModel(model: "defaultSounds", items: defaultSounds)
            ]),
            copyNameAction: copyAction,
            playAction: input.soundSelected.map { $0.model.url as CFURL }
        )
    }
}
