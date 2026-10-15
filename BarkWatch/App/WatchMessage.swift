//
//  WatchMessage.swift
//  Bark
//
//  Created by Jian Qin on 9/30/26.
//


import Observation
import os
import UserNotifications
import WatchKit
import WidgetKit

struct WatchMessage: Equatable, Sendable {
    let title: String
    let subtitle: String
    let body: String
    let markdown: String?
    let group: String
    let level: WatchNotificationLevel
    let url: URL?
    let image: URL?
    let identifier: String?
    let usedCriticalAlertFallback: Bool

    nonisolated init(content: UNNotificationContent) {
        title = content.title
        subtitle = content.subtitle
        body = content.body
        markdown = WatchNotification.stringValue("markdown", in: content.userInfo)
        group = content.threadIdentifier
        level = WatchNotificationLevel(content.interruptionLevel)
        url = WatchNotification.validatedWebURL(WatchNotification.stringValue("url", in: content.userInfo))
        image = WatchNotification.validatedWebURL(WatchNotification.stringValue("image", in: content.userInfo))
        identifier = WatchNotification.stringValue("id", in: content.userInfo)
        usedCriticalAlertFallback = content.userInfo[WatchNotification.criticalAlertFallbackKey] as? Bool ?? false
    }

    nonisolated init(archived message: WatchArchivedMessage) {
        title = message.title
        subtitle = message.subtitle ?? ""
        body = message.body
        markdown = message.markdown
        group = message.group
        level = message.level ?? .active
        url = WatchNotification.validatedWebURL(message.url)
        image = WatchNotification.validatedWebURL(message.image)
        identifier = message.id
        usedCriticalAlertFallback = message.usedCriticalAlertFallback ?? false
    }
}

@Observable
@MainActor
final class NotificationState {
    let servers: ServerManager
    enum PushRegistrationState {
        case idle
        case registering
        case registered(String)
        case failed(String)
    }

    var authorizationStatus: UNAuthorizationStatus?
    var registrationState: PushRegistrationState = .idle
    var isRequestingPermission = false
    var permissionError: String?
    var criticalAlertSetting: UNNotificationSetting?
    /// Most recently presented or opened notification. Restored from `WatchArchive`
    /// at launch; messages the archive skips (`isArchive=0`, `ttl<=0`) last only
    /// until the app quits.
    private(set) var lastMessage: WatchMessage?
    /// A link tapped in the notification interface, which can't show a browser itself.
    /// Held until the notification's response delivers the message, so the app can
    /// show Last message before opening the link.
    var requestedNotificationURL: URL?
    /// A link the app should open once it's active; set together with `lastMessage`.
    var pendingBrowserURL: URL?

    init(servers: ServerManager = ServerManager(), archive: WatchArchive = .shared) {
        self.servers = servers
        lastMessage = (try? archive.latest(group: nil)).flatMap(WatchMessage.init(archived:))
    }

    /// Shows the archived message a complication was displaying, falling back to
    /// the newest one if it has since expired. Returns whether a message is shown.
    func showArchivedMessage(id: String?, archive: WatchArchive = .shared) -> Bool {
        let archived = id.flatMap { try? archive.message(id: $0) } ?? (try? archive.latest(group: nil))
        if let archived { lastMessage = WatchMessage(archived: archived) }
        return lastMessage != nil
    }

    var hasNotificationPermission: Bool {
        authorizationStatus == .authorized || authorizationStatus == .provisional
    }

    /// Permission is granted and Apple has issued a device token; server delivery is separate.
    var isPushRegistrationReady: Bool {
        guard hasNotificationPermission,
              case .registered = registrationState else { return false }
        return true
    }
    
    /// Hide setup only when a server is saved and notification delivery is ready.
    var needsNotificationSetup: Bool {
        servers.servers.isEmpty || !isPushRegistrationReady
    }

    func receive(_ message: WatchMessage) {
        lastMessage = message
        Logger.links.debug("Received message, requested link: \(self.requestedNotificationURL?.absoluteString ?? "none")")
        if let requestedNotificationURL {
            pendingBrowserURL = requestedNotificationURL
            self.requestedNotificationURL = nil
        }
    }

    func refreshAndRegister() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
        criticalAlertSetting = settings.criticalAlertSetting
        let criticalAlerts = switch settings.criticalAlertSetting {
        case .enabled: "enabled"
        case .disabled: "disabled"
        default: "not supported by this signed app"
        }
        Logger.registration.debug("Critical alerts: \(criticalAlerts, privacy: .public)")
        guard hasNotificationPermission else {
            registrationState = .idle
            return
        }
        switch registrationState {
        case .idle, .failed:
            registrationState = .registering
            WKApplication.shared().registerForRemoteNotifications()
        case .registered(let deviceToken):
            await servers.syncAllServers(deviceToken: deviceToken)
        case .registering:
            break
        }
    }

    func removeMessage(withIdentifier identifier: String) {
        guard lastMessage?.identifier == identifier else { return }
        lastMessage = nil
        requestedNotificationURL = nil
        pendingBrowserURL = nil
    }

    func enableNotifications(includeCriticalAlerts: Bool = false) async {
        guard !isRequestingPermission else { return }
        isRequestingPermission = true
        permissionError = nil
        defer { isRequestingPermission = false }
        var options: UNAuthorizationOptions = [.alert, .sound]
        if includeCriticalAlerts { options.insert(.criticalAlert) }
        do {
            _ = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
        } catch {
            permissionError = error.localizedDescription
        }
        await refreshAndRegister()
    }
}

@MainActor
final class NotificationDelegate: NSObject, WKApplicationDelegate, UNUserNotificationCenterDelegate {
    let state = NotificationState()
    private let logger = Logger(subsystem: WatchConstants.bundleIdentifier, category: "NotificationDeletion")
    /// The live delegate. `WKApplication.shared().delegate` doesn't return it with
    /// `@WKApplicationDelegateAdaptor`, so the notification interface uses this.
    private(set) static weak var current: NotificationDelegate?

    override init() {
        super.init()
        Self.current = self
    }

    func applicationDidFinishLaunching() {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.delegate = self
        notificationCenter.setNotificationCategories([
            UNNotificationCategory(identifier: WatchNotification.markdownCategoryIdentifier,
                                   actions: [], intentIdentifiers: [])
        ])
        Task { await state.refreshAndRegister() }
    }

    func applicationDidBecomeActive() {
        Task { await state.refreshAndRegister() }
    }

    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02x", $0) }.joined()
        state.registrationState = .registered(tokenString)
        Task { await state.servers.syncAllServers(deviceToken: tokenString) }
        // Copyable from the Xcode console for manual push testing. Interpolated values
        // are private by default, so they are redacted unless a debugger is attached.
        Logger.registration.debug("Device token: \(tokenString)")
        Logger.registration.debug("Push topic: \(Bundle.main.bundleIdentifier ?? "unknown")")
    }

    func didFailToRegisterForRemoteNotificationsWithError(_ error: any Error) {
        state.registrationState = .failed(error.localizedDescription)
    }

    func didReceiveRemoteNotification(
        _ userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (WKBackgroundFetchResult) -> Void
    ) {
        completionHandler(handleRemoteNotification(userInfo))
    }

    func handleRemoteNotification(
        _ userInfo: [AnyHashable: Any], archive: WatchArchive = .shared
    ) -> WKBackgroundFetchResult {
        guard WatchNotification.stringValue("delete", in: userInfo) == "1",
              let identifier = WatchNotification.stringValue("id", in: userInfo),
              !identifier.isEmpty else { return .noData }

        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
        state.removeMessage(withIdentifier: identifier)
        do {
            if try archive.remove(id: identifier) {
                WidgetCenter.shared.reloadTimelines(ofKind: WatchArchive.widgetKind)
            }
            return .newData
        } catch {
            logger.error("Could not delete archived notification: \(error.localizedDescription)")
            return .failed
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        if WatchNotification.stringValue("delete", in: notification.request.content.userInfo) == "1" {
            let identifier = WatchNotification.stringValue("id", in: notification.request.content.userInfo)
            await MainActor.run {
                if let identifier { _ = handleRemoteNotification(["delete": "1", "id": identifier]) }
            }
            return []
        }
        let message = WatchMessage(content: notification.request.content)
        await MainActor.run { state.receive(message) }
        return WatchNotification.presentationOptions(for: notification.request.content)
    }

    // Main-actor isolated so the system's completion handler runs on the main thread.
    // Completing on a background thread crashes UIKit ("Call must be made on main
    // thread") when the app is launched from the notification interface.
    @MainActor
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard response.actionIdentifier != UNNotificationDismissActionIdentifier else { return }
        state.receive(WatchMessage(content: response.notification.request.content))
    }
}
