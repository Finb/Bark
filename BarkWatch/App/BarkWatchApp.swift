import SwiftUI
import WatchKit

@main
struct BarkWatchApp: App {
    @WKApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(appDelegate.model)
        }

        WKNotificationScene(
            controller: NotificationController.self,
            category: WatchNotificationCategory.markdown
        )
    }
}
