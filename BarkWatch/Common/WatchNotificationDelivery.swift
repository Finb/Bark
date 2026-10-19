//
//  WatchNotificationDelivery.swift
//  Bark
//
//  Created by Jian Qin on 10/9/26.
//

import Foundation
import Intents
import os
import UniformTypeIdentifiers
import UserNotifications

/// The notification service pipeline, kept out of the extension's principal class
/// so tests can drive it without APNs, the network, or a Siri donation.
///
/// Like the phone's `NotificationService`, one task runs the steps in order and a
/// copy of the content is published after each step. If the extension's time
/// expires, `finish` delivers the last published copy and cancels the task.
/// `finish` clears `contentHandler` under the lock before calling it, so the
/// content handler runs exactly once.
nonisolated final class WatchNotificationDelivery: @unchecked Sendable {
    /// Everything the pipeline touches outside its own state, so tests can replace it.
    struct Dependencies {
        var archive: WatchArchive = .shared
        var session: URLSession = .shared
        var cryptoFields: () throws -> CryptoSettingFields? = { try WatchCryptoStore.load() }
        var criticalAlertsEnabled: () async -> Bool = {
            await UNUserNotificationCenter.current().notificationSettings().criticalAlertSetting == .enabled
        }
        var donate: (INInteraction) async throws -> Void = { interaction in
            try await interaction.donate()
        }
    }

    private let dependencies: Dependencies
    private let logger = Logger(subsystem: WatchConstants.bundleIdentifier, category: "NotificationIcon")
    /// Images larger than this are not downloaded or attached.
    private let maximumImageSize = 5 * 1024 * 1024

    private let lock = NSLock()
    /// Cleared by `finish`; nil means the notification was already delivered.
    private var contentHandler: ((UNNotificationContent) -> Void)?
    /// A copy of the content after the last completed step, delivered on expiry.
    private var bestAttemptContent: UNNotificationContent?
    private var task: Task<Void, Never>?

    init(dependencies: Dependencies = Dependencies()) {
        self.dependencies = dependencies
    }

    func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        lock.withLock {
            self.contentHandler = contentHandler
            bestAttemptContent = request.content
        }
        let identifier = request.identifier
        let task = Task { await run(identifier: identifier) }
        lock.withLock {
            // `finish` may already have run if the extension expired immediately.
            if self.contentHandler == nil {
                task.cancel()
            } else {
                self.task = task
            }
        }
    }

    func serviceExtensionTimeWillExpire() {
        finish()
    }

    // MARK: - Pipeline

    /// Runs the steps in the same order as the phone's processors.
    private func run(identifier: String) async {
        // Start from the original content `didReceive` stored, so no
        // non-Sendable request has to be captured by the task.
        let original = lock.withLock { bestAttemptContent }
        guard let content = original?.mutableCopy() as? UNMutableNotificationContent else {
            finish()
            return
        }

        // ciphertext: must run first, the whole payload may be encrypted.
        // On failure, deliver the "Decryption Failed" content right away.
        guard decrypt(content) else {
            finish(with: content)
            return
        }
        publish(content)

        // markdown, level, badge
        WatchNotification.applyMarkdown(content)
        WatchNotification.applyGroup(content)
        let criticalAlertsEnabled = await dependencies.criticalAlertsEnabled()
        WatchNotification.applyLevel(content, criticalAlertsEnabled: criticalAlertsEnabled)
        WatchNotification.clearBadge(content)
        publish(content)

        // archive: after preparing, so the stored message matches what is shown.
        guard !Task.isCancelled else { return }
        archive(content, identifier: identifier)

        // setImage
        await attachImage(to: content)
        guard !Task.isCancelled else { return }
        publish(content)

        // setIcon: last, because the download and Siri donation may run out of time.
        let delivered = await applyIcon(to: content)
        finish(with: delivered)
    }

    private func decrypt(_ content: UNMutableNotificationContent) -> Bool {
        WatchEncryption.prepare(content, fields: dependencies.cryptoFields)
    }

    private func archive(_ content: UNMutableNotificationContent, identifier: String) {
        guard let message = WatchArchivedMessage(content: content, identifier: identifier) else {
            return
        }
        do {
            try dependencies.archive.save(message)
        } catch {
            logger.error("Could not archive notification: \(error.localizedDescription)")
        }
    }

    private func attachImage(to content: UNMutableNotificationContent) async {
        let address = WatchNotification.stringValue("image", in: content.userInfo)
        guard let file = await downloadImage(address) else {
            return
        }
        do {
            let attachment = try UNNotificationAttachment(identifier: "image", url: file, options: nil)
            content.attachments = [attachment]
        } catch {
            try? FileManager.default.removeItem(at: file)
        }
    }

    /// Shows the icon as the sender's avatar by donating a message intent.
    /// Returns the content unchanged if any part of that fails.
    private func applyIcon(to content: UNMutableNotificationContent) async -> UNMutableNotificationContent {
        guard let address = WatchNotification.stringValue("icon", in: content.userInfo) else {
            return content
        }
        let file = await downloadImage(address)
        defer {
            if let file {
                try? FileManager.default.removeItem(at: file)
            }
        }
        guard let file,
              let data = try? Data(contentsOf: file),
              let intent = WatchNotification.iconIntent(for: content, imageData: data) else {
            logger.error("Icon download or image validation failed; delivering original notification")
            return content
        }

        let interaction = INInteraction(intent: intent, response: nil)
        interaction.direction = .incoming
        do {
            try await dependencies.donate(interaction)
            guard let updated = try content.updating(from: intent).mutableCopy() as? UNMutableNotificationContent else {
                return content
            }
            // Preserve Bark's text and options while retaining the system's avatar metadata.
            updated.title = content.title
            updated.subtitle = content.subtitle
            updated.body = content.body
            updated.userInfo.merge(content.userInfo) { _, original in original }
            updated.threadIdentifier = content.threadIdentifier
            updated.categoryIdentifier = content.categoryIdentifier
            updated.sound = content.sound
            updated.interruptionLevel = content.interruptionLevel
            updated.attachments = content.attachments
            updated.badge = content.badge
            logger.info("Notification avatar applied")
            return updated
        } catch {
            logger.error("Notification avatar failed: \(error.localizedDescription)")
            return content
        }
    }

    /// Downloads a PNG, JPEG, or GIF and returns a temporary file with a matching
    /// extension, or nil if the address or response is not acceptable.
    /// Cancelling the task cancels the download.
    private func downloadImage(_ address: String?) async -> URL? {
        guard let url = WatchNotification.validatedWebURL(address) else {
            return nil
        }
        let request = URLRequest(url: url, timeoutInterval: 8)
        guard let downloaded = try? await dependencies.session.download(for: request) else {
            return nil
        }
        let (file, response) = downloaded
        let acceptedTypes = ["image/png", "image/jpeg", "image/gif"]
        guard let response = response as? HTTPURLResponse,
              response.statusCode == 200,
              let mime = response.mimeType,
              acceptedTypes.contains(mime),
              let suffix = UTType(mimeType: mime)?.preferredFilenameExtension,
              let size = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize,
              size <= maximumImageSize else {
            try? FileManager.default.removeItem(at: file)
            return nil
        }
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(suffix)
        do {
            try FileManager.default.moveItem(at: file, to: destination)
            return destination
        } catch {
            try? FileManager.default.removeItem(at: file)
            return nil
        }
    }

    // MARK: - Delivery

    /// Stores a copy, so the content handed to the system on expiry is never
    /// changed afterwards by the running task.
    private func publish(_ content: UNMutableNotificationContent) {
        let snapshot = content.copy() as? UNNotificationContent
        lock.withLock {
            bestAttemptContent = snapshot
        }
    }

    /// Delivers `content`, or the last published copy, exactly once.
    private func finish(with content: UNNotificationContent? = nil) {
        let (handler, result, task) = lock.withLock {
            let taken = (contentHandler, content ?? bestAttemptContent, self.task)
            contentHandler = nil
            self.task = nil
            return taken
        }
        task?.cancel()
        if let handler, let result {
            handler(result)
        }
    }
}
