import CryptoKit
import Foundation
import UniformTypeIdentifiers

/// 手表端的推送图片缓存，保存在 App Group 中，通知扩展与 App 共享。
/// 缓存按 URL 哈希命名，图片每次被使用时通过文件修改时间续期。
enum WatchImageCache {
    /// 单张图片大小上限，与原通知扩展的下载逻辑一致。
    static let maxFileSize = 5 * 1024 * 1024
    static let downloadTimeout: TimeInterval = 5
    /// 超过 30 天未使用的图片会被删除，与 soundUrl 缓存一致。
    static let maxCacheAge: TimeInterval = 30 * 24 * 60 * 60
    /// 缓存总量上限，超过后按最后使用时间淘汰，与 soundUrl 缓存一致。
    static let maxCacheSize = 20 * 1024 * 1024

    private static let fileNamePrefix = "bark.image."
    private static let attachmentsDirectoryName = "BarkWatchAttachments"

    static var directoryUrl: URL? {
        guard let groupUrl = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.bark"
        ) else {
            return nil
        }
        let directory = groupUrl.appendingPathComponent("Library/Caches/BarkWatchImages", isDirectory: true)
        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }

    /// 返回缓存中的图片文件；命中时更新修改时间，作为最后使用时间。
    static func cachedFile(for url: URL) -> URL? {
        guard let directoryUrl,
              let file = cachedFile(prefix: cachePrefix(for: url), in: directoryUrl)
        else {
            return nil
        }
        touch(file)
        return file
    }

    /// 读取图片数据，优先使用本地缓存，未命中时下载。
    static func data(for url: URL) async -> Data? {
        if let cached = cachedFile(for: url) {
            return try? Data(contentsOf: cached)
        }
        guard let file = await downloadIfNeeded(url) else {
            return nil
        }
        return try? Data(contentsOf: file)
    }

    /// 下载并缓存图片；命中缓存时直接返回并续期。
    static func downloadIfNeeded(_ url: URL) async -> URL? {
        if let cached = cachedFile(for: url) {
            return cached
        }
        guard let directoryUrl else {
            return nil
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = downloadTimeout

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode),
              !data.isEmpty,
              data.count <= maxFileSize
        else {
            return nil
        }

        let prefix = cachePrefix(for: url)
        let fileExtension = fileExtension(for: url, mimeType: http.mimeType)
        let destination = directoryUrl.appendingPathComponent("\(prefix)\(fileExtension)")
        do {
            try data.write(to: destination, options: .atomic)
            return destination
        } catch {
            // 另一个进程可能刚写入了同一张图片。
            guard let cached = cachedFile(prefix: prefix, in: directoryUrl) else {
                return nil
            }
            touch(cached)
            return cached
        }
    }

    /// 清理超过 `maxCacheAge` 的图片，再按最后使用时间淘汰直到总量不超过 `maxCacheSize`。
    /// `keeping` 永不删除。
    static func cleanupCache(keeping: URL? = nil) {
        guard let directoryUrl,
              let files = try? FileManager.default.contentsOfDirectory(
                  at: directoryUrl,
                  includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]
              )
        else {
            return
        }

        let keepingName = keeping?.lastPathComponent
        let cutoff = Date().addingTimeInterval(-maxCacheAge)
        var remaining: [(url: URL, used: Date, size: Int)] = []

        for file in files where file.lastPathComponent.hasPrefix(fileNamePrefix) {
            let values = try? file.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
            let used = values?.contentModificationDate ?? .distantPast
            let size = values?.fileSize ?? 0
            if used < cutoff, file.lastPathComponent != keepingName {
                try? FileManager.default.removeItem(at: file)
            } else {
                remaining.append((file, used, size))
            }
        }

        var totalSize = remaining.reduce(0) { $0 + $1.size }
        for file in remaining.sorted(by: { $0.used < $1.used }) where totalSize > maxCacheSize {
            if file.url.lastPathComponent == keepingName {
                continue
            }
            try? FileManager.default.removeItem(at: file.url)
            totalSize -= file.size
        }
    }

    /// 把缓存文件复制到临时目录，交给 `UNNotificationAttachment`。
    static func copyForAttachment(_ cached: URL) -> URL? {
        let directory = attachmentsDirectoryUrl
        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        var destination = directory.appendingPathComponent(UUID().uuidString)
        let fileExtension = cached.pathExtension
        if !fileExtension.isEmpty {
            destination = destination.appendingPathExtension(fileExtension)
        }

        do {
            try FileManager.default.copyItem(at: cached, to: destination)
            return destination
        } catch {
            return nil
        }
    }
}

private extension WatchImageCache {
    static var attachmentsDirectoryUrl: URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(attachmentsDirectoryName, isDirectory: true)
    }

    static func cachePrefix(for url: URL) -> String {
        let hash = SHA256.hash(data: Data(url.absoluteString.utf8))
            .prefix(12)
            .map { String(format: "%02x", $0) }
            .joined()
        return "\(fileNamePrefix)\(hash)."
    }

    static func cachedFile(prefix: String, in directory: URL) -> URL? {
        (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ))?.first { $0.lastPathComponent.hasPrefix(prefix) }
    }

    static func fileExtension(for url: URL, mimeType: String?) -> String {
        if let mimeType,
           let fileExtension = UTType(mimeType: mimeType)?.preferredFilenameExtension,
           !fileExtension.isEmpty {
            return fileExtension
        }
        return url.pathExtension.isEmpty ? "png" : url.pathExtension
    }

    static func touch(_ file: URL) {
        try? FileManager.default.setAttributes(
            [.modificationDate: Date()],
            ofItemAtPath: file.path
        )
    }
}
