//
//  NotificationMarkdownView.swift
//  Bark
//
//  Created by Jian Qin on 9/30/26.
//

import os
import SwiftUI
import UserNotifications
import WatchKit

final class MarkdownNotificationController: WKUserNotificationHostingController<MarkdownNotificationView> {
    private var content: UNNotificationContent?

    override var body: MarkdownNotificationView {
        MarkdownNotificationView(content: content) { [weak self] url in self?.open(url) }
    }
    override class var isInteractive: Bool { true }

    /// Hand the link to the app, then launch it; the app opens the link in a browser session.
    private func open(_ url: URL) {
        let delegate = NotificationDelegate.current
        delegate?.state.requestedNotificationURL = url
        Logger.links.debug("Notification requested \(url), delegate found: \(delegate != nil)")
        performNotificationDefaultAction()
    }

    override func didReceive(_ notification: UNNotification) {
        content = notification.request.content
    }
}

struct MarkdownNotificationView: View {
    let content: UNNotificationContent?
    var openLink: (URL) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let content {
                if !content.title.isEmpty { Text(content.title).font(.headline) }
                if !content.subtitle.isEmpty { Text(content.subtitle).font(.subheadline) }
                if let source = WatchNotification.stringValue("markdown", in: content.userInfo),
                   !source.isEmpty, content.userInfo["ciphertext"] == nil {
                    WatchMarkdownView(source: source, openLink: openLink)
                } else {
                    Text(content.body)
                }
                if let url = WatchNotification.validatedWebURL(WatchNotification.stringValue("image", in: content.userInfo)) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                }
                if let url = WatchNotification.validatedWebURL(WatchNotification.stringValue("url", in: content.userInfo)) {
                    Button("Open link") { openLink(url) }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Markdown notification") {
    let content = UNMutableNotificationContent()
    content.title = "Markdown on watch"
    content.userInfo = ["markdown": """
    # Training
    **Strong**, *emphasis*, ~~removed~~ and `code`.

    > Steady effort.

    3. Warm up
    4. Main set
       - Recover

    ```swift
    let distance = 42
    ```

    [Bark](https://bark.day.app)
    """]
    return ScrollView {
        MarkdownNotificationView(content: content).padding()
    }
}
