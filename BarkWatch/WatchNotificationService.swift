import Foundation
import Intents
import os
import UniformTypeIdentifiers
import UserNotifications
import WidgetKit

final class NotificationService: UNNotificationServiceExtension {
    private let lock = NSLock()
    private var handler: ((UNNotificationContent) -> Void)?
    private var content: UNMutableNotificationContent?
    private var download: URLSessionDownloadTask?
    private let logger = Logger(subsystem: "com.sebersta.BarkWatchPrototype", category: "NotificationIcon")

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        guard let content = request.content.mutableCopy() as? UNMutableNotificationContent else {
            contentHandler(request.content)
            return
        }
        lock.lock()
        self.content = content
        handler = contentHandler
        let decrypted = WatchEncryption.prepare(content) { try WatchCryptoStore.load() }
        lock.unlock()
        guard decrypted else {
            finish()
            return
        }
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            self?.process(criticalAlertsEnabled: settings.criticalAlertSetting == .enabled,
                          identifier: request.identifier)
        }
    }

    private func process(criticalAlertsEnabled: Bool, identifier: String) {
        lock.lock()
        guard handler != nil, let content else {
            lock.unlock()
            return
        }
        WatchNotification.prepare(content, criticalAlertsEnabled: criticalAlertsEnabled)
        // Archived after preparing so the level and markdown summary match what is shown.
        let archived = WatchArchivedMessage(content: content, identifier: identifier)
        lock.unlock()
        if let archived {
            do {
                try WatchArchive.shared.save(archived)
                WidgetCenter.shared.reloadTimelines(ofKind: WatchArchive.widgetKind)
            } catch {
                logger.error("Could not archive notification: \(error.localizedDescription)")
            }
        }
        downloadImage(WatchNotification.stringValue("image", in: content.userInfo)) { [weak self] file in
            guard let self else { return }
            let attachment = file.flatMap { try? UNNotificationAttachment(identifier: "image", url: $0, options: nil) }
            if attachment == nil, let file { try? FileManager.default.removeItem(at: file) }
            self.lock.lock()
            if self.handler != nil, let attachment { self.content?.attachments = [attachment] }
            self.lock.unlock()
            self.processIcon()
        }
    }

    private func processIcon() {
        lock.lock()
        let snapshot = handler == nil ? nil : content?.mutableCopy() as? UNMutableNotificationContent
        lock.unlock()
        guard let snapshot else { return }
        guard WatchNotification.stringValue("icon", in: snapshot.userInfo) != nil else {
            finish()
            return
        }
        downloadImage(WatchNotification.stringValue("icon", in: snapshot.userInfo)) { [weak self] file in
            defer { if let file { try? FileManager.default.removeItem(at: file) } }
            guard let self else { return }
            guard let file, let data = try? Data(contentsOf: file),
                  let intent = WatchNotification.iconIntent(for: snapshot, imageData: data) else {
                self.logger.error("Icon download or image validation failed; delivering original notification")
                self.finish()
                return
            }
            let interaction = INInteraction(intent: intent, response: nil)
            interaction.direction = .incoming
            interaction.donate { [weak self] error in
                guard let self else { return }
                do {
                    if let error { throw error }
                    guard let updated = try snapshot.updating(from: intent).mutableCopy() as? UNMutableNotificationContent else {
                        self.finish()
                        return
                    }
                    // Preserve Bark's text and options while retaining the system's avatar metadata.
                    updated.title = snapshot.title
                    updated.subtitle = snapshot.subtitle
                    updated.body = snapshot.body
                    updated.userInfo.merge(snapshot.userInfo) { _, original in original }
                    updated.threadIdentifier = snapshot.threadIdentifier
                    updated.categoryIdentifier = snapshot.categoryIdentifier
                    updated.sound = snapshot.sound
                    updated.interruptionLevel = snapshot.interruptionLevel
                    updated.attachments = snapshot.attachments
                    updated.badge = snapshot.badge
                    self.logger.info("Notification avatar applied")
                    self.finish(updated: updated)
                } catch {
                    self.logger.error("Notification avatar failed: \(error.localizedDescription)")
                    self.finish()
                }
            }
        }
    }

    private func downloadImage(_ address: String?, completion: @escaping (URL?) -> Void) {
        guard let url = WatchNotification.validatedWebURL(address) else {
            completion(nil)
            return
        }
        let task = URLSession.shared.downloadTask(with: URLRequest(url: url, timeoutInterval: 8)) { [weak self] file, response, _ in
            var imageFile: URL?
            if let file, let response = response as? HTTPURLResponse, response.statusCode == 200,
               let mime = response.mimeType, ["image/png", "image/jpeg", "image/gif"].contains(mime),
               let type = UTType(mimeType: mime), let suffix = type.preferredFilenameExtension,
               let size = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize, size <= 5 * 1024 * 1024 {
                let destination = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension(suffix)
                do {
                    try FileManager.default.moveItem(at: file, to: destination)
                    imageFile = destination
                } catch {
                    try? FileManager.default.removeItem(at: destination)
                }
            }
            guard let self else { return }
            self.lock.lock()
            let isActive = self.handler != nil
            self.lock.unlock()
            if isActive { completion(imageFile) }
            else if let imageFile { try? FileManager.default.removeItem(at: imageFile) }
        }
        lock.lock()
        download = task
        let shouldStart = handler != nil
        lock.unlock()
        if shouldStart { task.resume() } else { task.cancel() }
    }

    override func serviceExtensionTimeWillExpire() { finish() }

    private func finish(updated: UNMutableNotificationContent? = nil) {
        lock.lock()
        let callback = handler
        let result = updated ?? content
        handler = nil
        let task = download
        download = nil
        lock.unlock()
        task?.cancel()
        if let callback, let result { callback(result) }
    }
}
