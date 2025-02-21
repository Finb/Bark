//
//  OptionsProvider.swift
//  Bark
//
//  Created by huangfeng on 2/21/25.
//  Copyright © 2025 Fin. All rights reserved.
//
import AppIntents

@available(iOS 16, *)
struct ServerAddressOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> [String] {
        return ServerManager.shared.servers.map { server in
            return server.address + "/" + server.key
        }
    }

    func defaultResult() async -> String? {
        return ServerManager.shared.currentServer.address + "/" + ServerManager.shared.currentServer.key
    }
}

@available(iOS 16, *)
struct SoundOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> [String] {
        var customSounds: [String] = []
        if let soundsDirectoryUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.bark")?.appendingPathComponent("Library/Sounds").path {
            customSounds = getSounds(urls: getFilesInDirectory(directory: soundsDirectoryUrl, suffix: "caf"))
        }
        let defaultSounds = getSounds(urls: Bundle.main.urls(forResourcesWithExtension: "caf", subdirectory: nil) ?? [])
        
        return customSounds + defaultSounds
    }
    
    func getSounds(urls: [URL]) -> [String] {
        let urls = urls.sorted { u1, u2 -> Bool in
            u1.lastPathComponent.localizedStandardCompare(u2.lastPathComponent) == ComparisonResult.orderedAscending
        }
        return urls.map { $0.deletingPathExtension().lastPathComponent }
    }
    
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
}

@available(iOS 16, *)
struct VolumeOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> [Int] {
        return Array(0...10)
    }
}
