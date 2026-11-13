import SwiftUI
import UserNotifications
import WatchKit

final class NotificationController: WKUserNotificationHostingController<NotificationView> {
    private var content: UNNotificationContent?
    private var markdown: AttributedString?

    override var body: NotificationView {
        NotificationView(content: content, markdown: markdown)
    }

    override class var isInteractive: Bool { true }

    override func didReceive(_ notification: UNNotification) {
        let content = notification.request.content
        self.content = content

        if let source = content.userInfo["markdown"] as? String, !source.isEmpty {
            markdown = MarkdownText.swiftUIAttributed(source)
        }
    }
}

struct NotificationView: View {
    let content: UNNotificationContent?
    let markdown: AttributedString?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                if let content {
                    if !content.title.isEmpty {
                        Text(verbatim: content.title)
                            .font(.headline)
                    }

                    if !content.subtitle.isEmpty {
                        Text(verbatim: content.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let markdown {
                        Text(markdown)
                    } else if !content.body.isEmpty {
                        Text(verbatim: content.body)
                    }

                    if let image = content.userInfo["image"] as? String,
                       let url = URL(string: image) {
                        WatchCachedImage(url: url, cornerRadius: 6)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
