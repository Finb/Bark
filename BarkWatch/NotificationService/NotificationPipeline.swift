import Foundation
import UniformTypeIdentifiers
import UserNotifications

enum NotificationPipeline {
    /// 解密、markdown、分组、级别、归档。图片下载单独执行，避免拖慢归档。
    static func prepare(
        _ content: UNMutableNotificationContent,
        identifier: String
    ) async -> UNMutableNotificationContent {
        var userInfo = content.userInfo

        if let ciphertext = userInfo["ciphertext"] as? String {
            do {
                userInfo = try decrypt(ciphertext, iv: stringValue(userInfo["iv"]))
                content.userInfo = userInfo
                content.title = stringValue(userInfo["title"]) ?? ""
                content.subtitle = stringValue(userInfo["subtitle"]) ?? ""
                content.body = stringValue(userInfo["body"]) ?? ""
            } catch {
                content.title = "Decryption Failed"
                content.subtitle = ""
                content.body = error.rawString()
                return content
            }
        }

        if let markdown = stringValue(userInfo["markdown"]), !markdown.isEmpty {
            content.body = MarkdownText.plain(markdown)
            content.categoryIdentifier = WatchNotificationCategory.markdown
        }

        if let group = stringValue(userInfo["group"]), !group.isEmpty {
            content.threadIdentifier = group
        }

        await applyLevel(to: content)
        await archive(content, identifier: identifier)
        return content
    }

    static func attachImage(to content: UNMutableNotificationContent) async -> UNMutableNotificationContent {
        guard let image = stringValue(content.userInfo["image"]),
              let url = URL(string: image),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else {
            return content
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 5

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode),
              !data.isEmpty,
              data.count <= 5 * 1024 * 1024
        else {
            return content
        }

        let fileExtension = http.mimeType.flatMap { UTType(mimeType: $0)?.preferredFilenameExtension }
            ?? (url.pathExtension.isEmpty ? "png" : url.pathExtension)
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(fileExtension)

        guard (try? data.write(to: fileURL)) != nil,
              let attachment = try? UNNotificationAttachment(identifier: "image", url: fileURL, options: nil)
        else {
            return content
        }

        content.attachments = [attachment]
        return content
    }
}

private extension NotificationPipeline {
    static func applyLevel(to content: UNMutableNotificationContent) async {
        guard let level = stringValue(content.userInfo["level"]) else { return }

        if level == "critical", await criticalAlertsEnabled() {
            var volume: Float = 0.5
            if let value = stringValue(content.userInfo["volume"]), let parsed = Float(value) {
                volume = min(max(parsed / 10, 0), 1)
            }
            content.interruptionLevel = .critical
            content.sound = .defaultCriticalSound(withAudioVolume: volume)
            return
        }

        switch level {
        case "passive":
            content.interruptionLevel = .passive
        case "timeSensitive", "timesensitive", "critical":
            content.interruptionLevel = .timeSensitive
        default:
            content.interruptionLevel = .active
        }
    }

    static func criticalAlertsEnabled() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.criticalAlertSetting == .enabled
    }

    static func archive(_ content: UNMutableNotificationContent, identifier: String) async {
        let userInfo = content.userInfo

        if stringValue(userInfo["isarchive"]) == "0" {
            return
        }

        var expireDate: Date?
        if let ttl = stringValue(userInfo["ttl"]), let seconds = Int(ttl) {
            guard seconds > 0 else { return }
            expireDate = Date().addingTimeInterval(TimeInterval(seconds))
        }

        let id = stringValue(userInfo["id"]).flatMap { $0.isEmpty ? nil : $0 } ?? identifier
        let group = stringValue(userInfo["group"]).flatMap { $0.isEmpty ? nil : $0 }
            ?? (content.threadIdentifier.isEmpty ? nil : content.threadIdentifier)
            ?? ""

        let markdown = stringValue(userInfo["markdown"]).flatMap { $0.isEmpty ? nil : $0 }

        let message = WatchMessage(
            id: id,
            title: content.title.isEmpty ? nil : content.title,
            subtitle: content.subtitle.isEmpty ? nil : content.subtitle,
            markdown: markdown,
            body: content.body.isEmpty ? nil : content.body,
            url: stringValue(userInfo["url"]),
            image: stringValue(userInfo["image"]),
            group: group,
            createDate: Date(),
            expireDate: expireDate
        )
        await MessageStore.shared.save(message)
    }

    static func decrypt(_ ciphertext: String, iv: String?) throws -> [AnyHashable: Any] {
        guard var fields = CryptoSettingManager.shared.fields else {
            throw "No encryption key set"
        }
        if let iv, !iv.isEmpty {
            fields.iv = iv
        }

        let text = try AESCryptoModel(cryptoFields: fields).decrypt(ciphertext: ciphertext)
        guard let data = text.data(using: .utf8),
              let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        else {
            throw "JSON parsing failed"
        }

        var result: [AnyHashable: Any] = [:]
        for (key, value) in json {
            result[key.lowercased()] = stringValue(value) ?? value
        }
        return result
    }

    static func stringValue(_ value: Any?) -> String? {
        if let string = value as? String {
            return string
        }
        if let number = value as? NSNumber {
            return number.stringValue
        }
        return nil
    }
}
