//
//  WatchNotification.swift
//  Bark
//
//  Created by Jian Qin on 9/30/26.
//

import Foundation
import ImageIO
import Intents
import UserNotifications

nonisolated enum WatchNotification {
    static let markdownCategoryIdentifier = "BarkMarkdown"
    static let criticalAlertFallbackKey = WatchArchivedMessage.criticalAlertFallbackKey

    static func stringValue(_ key: String, in userInfo: [AnyHashable: Any]) -> String? {
        if let value = userInfo[key] as? String { return value }
        return (userInfo[key] as? NSNumber)?.stringValue
    }

    static func validatedWebURL(_ value: String?) -> URL? {
        guard let value, let url = URL(string: value),
              ["https", "http"].contains(url.scheme?.lowercased() ?? ""),
              let host = url.host, !host.isEmpty, url.user == nil, url.password == nil else { return nil }
        return url
    }

    static func markdownSummary(_ source: String) -> String {
        WatchMarkdownParser.parse(source, configuration: .clear).string
            .replacingOccurrences(of: "\n\n+", with: "\n", options: .regularExpression)
    }

    static func iconIntent(for content: UNNotificationContent, imageData: Data) -> INSendMessageIntent? {
        guard let iconURL = validatedWebURL(stringValue("icon", in: content.userInfo)),
              imageData.count <= 5 * 1024 * 1024,
              let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
              CGImageSourceGetCount(imageSource) > 0 else { return nil }
        let senderName = content.title.isEmpty ? "Bark" : content.title
        var nameComponents = PersonNameComponents()
        nameComponents.nickname = senderName
        let sender = INPerson(
            personHandle: INPersonHandle(value: iconURL.absoluteString, type: .unknown),
            nameComponents: nameComponents, displayName: senderName, image: INImage(imageData: imageData),
            contactIdentifier: nil, customIdentifier: iconURL.absoluteString
        )
        return INSendMessageIntent(
            recipients: nil, outgoingMessageType: .outgoingMessageText, content: content.body,
            speakableGroupName: nil,
            conversationIdentifier: content.threadIdentifier.isEmpty ? iconURL.absoluteString : content.threadIdentifier,
            serviceName: nil, sender: sender, attachments: nil
        )
    }

    static func criticalSoundVolume(_ userInfo: [AnyHashable: Any]) -> Float {
        guard let volumeText = stringValue("volume", in: userInfo),
              let volume = Float(volumeText), volume.isFinite else { return 0.5 }
        return min(1, max(0, volume / 10))
    }

    /// Runs every content step in the same order as the notification pipeline.
    static func prepare(_ content: UNMutableNotificationContent, criticalAlertsEnabled: Bool = false) {
        applyMarkdown(content)
        applyGroup(content)
        applyLevel(content, criticalAlertsEnabled: criticalAlertsEnabled)
        clearBadge(content)
    }

    /// Matches the phone's `MarkdownProcessor`: shows a plain-text summary as the body.
    static func applyMarkdown(_ content: UNMutableNotificationContent) {
        guard let markdown = stringValue("markdown", in: content.userInfo), !markdown.isEmpty else { return }
        content.body = markdownSummary(markdown)
        content.categoryIdentifier = markdownCategoryIdentifier
        var aps = content.userInfo["aps"] as? [String: Any] ?? [:]
        var alert = aps["alert"] as? [String: Any] ?? [:]
        alert["body"] = content.body
        aps["alert"] = alert
        content.userInfo["aps"] = aps
    }

    static func applyGroup(_ content: UNMutableNotificationContent) {
        if let group = stringValue("group", in: content.userInfo) {
            content.threadIdentifier = group
        }
    }

    /// Matches the phone's `LevelProcessor`. The sound is chosen here because it
    /// depends on the final level, after an unauthorized critical alert is downgraded.
    static func applyLevel(_ content: UNMutableNotificationContent, criticalAlertsEnabled: Bool = false) {
        let userInfo = content.userInfo
        if let requestedLevel = stringValue("level", in: userInfo)?.lowercased() {
            content.interruptionLevel = switch requestedLevel {
            case "passive": .passive
            case "timesensitive", "time-sensitive": .timeSensitive
            case "critical": .critical
            default: .active
            }
        }
        let requestsCriticalAlert = content.interruptionLevel == .critical
        if requestsCriticalAlert {
            content.interruptionLevel = criticalAlertsEnabled ? .critical : .active
        }
        content.userInfo[criticalAlertFallbackKey] = requestsCriticalAlert && !criticalAlertsEnabled
        let aps = userInfo["aps"] as? [String: Any] ?? [:]
        let criticalSound = aps["sound"] as? [String: Any]
        let soundName = (stringValue("sound", in: userInfo) ?? aps["sound"] as? String ?? criticalSound?["name"] as? String)?.lowercased()
        if content.interruptionLevel == .passive || soundName == "silent" || soundName == "silent.caf" {
            content.sound = nil
        } else if content.interruptionLevel == .critical {
            content.sound = .defaultCriticalSound(withAudioVolume: criticalSoundVolume(userInfo))
        } else {
            // watchOS supports the system notification sound, not named custom sounds.
            content.sound = .default
        }
    }

    /// Matches the phone's `BadgeProcessor`; the watch never shows a badge.
    static func clearBadge(_ content: UNMutableNotificationContent) {
        content.badge = nil
    }

    static func presentationOptions(for content: UNNotificationContent) -> UNNotificationPresentationOptions {
        guard content.interruptionLevel != .passive else { return [.list] }
        var options: UNNotificationPresentationOptions = [.banner, .list]
        if content.sound != nil { options.insert(.sound) }
        return options
    }
}
