//
//  NotificationMarkdownView.swift
//  Bark
//
//  Created by Jian Qin on 9/30/26.
//


import SwiftUI
import UIKit
import UserNotifications
import WatchKit

/// Markdown rendering for the notification interface (long look), kept separate from
/// the in-app `WatchMarkdownView` so it can be styled for the notification platter
/// without affecting the app. Shares parsing through `WatchMarkdownParagraph`.
struct NotificationMarkdownView: View {
    let source: String
    /// The notification interface can't open a browser, so links go to the controller.
    var openLink: (URL) -> Void = { _ in }
    @ScaledMetric(relativeTo: .body) private var fontSize = 14

    var body: some View {
        let text = WatchMarkdownParser.parse(source, configuration: .init(baseFont: .systemFont(ofSize: fontSize)))
        VStack(alignment: .leading, spacing: 0) {
            ForEach(WatchMarkdownParagraph.paragraphs(from: text)) { paragraph in
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    if let marker = paragraph.marker {
                        Text(marker)
                            .fixedSize(horizontal: true, vertical: false)
                            .frame(minWidth: paragraph.markerWidth, alignment: .leading)
                    }
                    Text(paragraph.text)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(paragraph.isCode ? 6 : 0)
                .background(paragraph.isCode ? Color.white.opacity(0.12) : .clear,
                            in: RoundedRectangle(cornerRadius: 6))
                .padding(.leading, paragraph.indent)
                .padding(.top, paragraph.spaceBefore)
                .accessibilityElement(children: .combine)
            }
        }
        .tint(.cyan)
        // Paragraphs already contain only web links; anything else is discarded.
        .environment(\.openURL, OpenURLAction { url in
            guard WatchNotification.validatedWebURL(url.absoluteString) != nil else { return .discarded }
            openLink(url)
            return .handled
        })
    }
}

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
        #if DEBUG
        print("Bark watch link: notification requested \(url), delegate found: \(delegate != nil)")
        #endif
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
                    NotificationMarkdownView(source: source, openLink: openLink)
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
