//
//  MessageImageCleaner.swift
//  Bark
//
//  Created by Cnitor on 2026/8/26.
//  Copyright © 2026 Cnitor. All rights reserved.
//

import Foundation
import Kingfisher
import RealmSwift

/*
 消息记录里的 image 字段只保存图片地址，图片本体由 NotificationServiceExtension 下载后，
 存放在 App Groups 共享的 Kingfisher 图片缓存中（详见 ImageDownloader）。
 存入时用的是 StorageExpiration.never，不会自动过期，所以消息删除后必须主动清理，否则图片文件会一直残留。

 通知中心里推送显示的图不受影响，那是 NSE 复制出来的附件副本。
 但下拉查看大图读的是同一份缓存，缓存删掉后会重新联网下载，离线时那条推送的大图就显示不出来了，
 这是删图片必然要付出的代价。
 */
class MessageImageCleaner {
    static let shared = MessageImageCleaner()

    private let cleanQueue = DispatchQueue(label: "me.fin.bark.message-image-clean", qos: .utility)

    /// 与 ImageDownloader 使用同一个图片缓存
    private lazy var imageCache: ImageCache? = {
        guard let groupUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.bark") else {
            return nil
        }
        return try? ImageCache(name: "shared", cacheDirectoryURL: groupUrl)
    }()

    private init() {}

    /// 收集这些消息引用的图片地址，需要在消息删除`之前`调用
    func imageUrls(in messages: Results<Message>) -> [String] {
        // 不用 distinct(by:)，image 字段没有加索引，交给 Set 去重更稳妥
        return Array(Set(messages.filter("image != nil").compactMap { $0.image }))
    }

    /// 删除不再被任何消息引用的图片缓存，需要在消息删除`之后`调用
    func removeUnreferencedImages(_ imageUrls: [String?]) {
        let candidates = Set(imageUrls.compactMap { $0 })
        guard !candidates.isEmpty else {
            return
        }

        cleanQueue.async {
            guard let cache = self.imageCache, let realm = try? Realm() else {
                return
            }

            // 同一个图片地址可能被多条消息引用，所以先取出所有仍被引用的地址
            // image 字段没有加索引，逐个地址去查会退化成多次全表扫描，所以只扫一遍
            let referenced = Set(
                realm.objects(Message.self)
                    .filter("image != nil")
                    .compactMap { $0.image }
            )

            for imageUrl in candidates.subtracting(referenced) {
                guard let url = URL(string: imageUrl) else {
                    continue
                }
                // 缓存 key 与 ImageDownloader 存入时保持一致
                cache.removeImage(forKey: url.cacheKey, fromMemory: true, fromDisk: true)
            }
        }
    }
}
