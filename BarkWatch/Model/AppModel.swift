import Foundation
import Observation
import UserNotifications
import WatchKit

@MainActor
@Observable
final class AppModel {
    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    var criticalAlertSetting: UNNotificationSetting = .notSupported
    var permissionChecked = false
    var deviceToken: String?

    let servers = ServerStore()
    let messages = MessageList()

    var notificationsAllowed: Bool {
        authorizationStatus == .authorized || authorizationStatus == .provisional
    }

    var needsPermission: Bool {
        !notificationsAllowed || criticalAlertSetting == .disabled
    }

    func start() async {
        await refresh()
    }

    func refresh() async {
        let (status, critical) = await Self.loadPermission()
        authorizationStatus = status
        criticalAlertSetting = critical
        permissionChecked = true

        if notificationsAllowed, deviceToken == nil {
            WKApplication.shared().registerForRemoteNotifications()
        }

        servers.reload()
        messages.reload()
    }

    func requestAuthorization() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .criticalAlert])
    }

    func didRegister(deviceToken: String) {
        self.deviceToken = deviceToken
        servers.sync(deviceToken: deviceToken)
    }

    nonisolated private static func loadPermission() async -> (UNAuthorizationStatus, UNNotificationSetting) {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return (settings.authorizationStatus, settings.criticalAlertSetting)
    }
}
