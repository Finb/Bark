import Foundation
import UserNotifications
import WatchKit

@MainActor
final class AppDelegate: NSObject, WKApplicationDelegate, UNUserNotificationCenterDelegate {
    let model = AppModel()

    func applicationDidFinishLaunching() {
        PhoneSyncManager.shared.activate()

        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.setNotificationCategories([
            UNNotificationCategory(
                identifier: WatchNotificationCategory.markdown,
                actions: [],
                intentIdentifiers: [],
                options: []
            )
        ])
        Task { await model.start() }
    }

    func applicationDidBecomeActive() {
        Task { await model.refresh() }
    }

    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        model.didRegister(deviceToken: token)
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        await MainActor.run { model.messages.reload() }
        return [.banner, .sound, .list]
    }
}
