//
//  BarkWatchApp.swift
//  Bark
//
//  Created by Jian Qin on 9/30/26.
//


import SwiftUI
import WatchKit

@main
struct BarkWatchApp: App {
    @WKApplicationDelegateAdaptor(NotificationDelegate.self) private var delegate

    var body: some Scene {
        WindowGroup {
            ContentView(state: delegate.state)
        }
        WKNotificationScene(controller: MarkdownNotificationController.self,
                            category: WatchNotification.markdownCategoryIdentifier)
    }
}
