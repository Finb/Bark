import CoreText
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
            markdown = Self.attributedString(from: MarkdownText.attributed(source))
        }
    }

    private static func attributedString(from text: NSAttributedString) -> AttributedString {
        var result = AttributedString()

        text.enumerateAttributes(in: NSRange(location: 0, length: text.length)) { attributes, range, _ in
            var run = AttributedString(text.attributedSubstring(from: range).string)

            if let font = attributes[.font] as? UIFont {
                run.font = Font(font as CTFont)
            }
            if let color = attributes[.foregroundColor] as? UIColor {
                run.foregroundColor = Color(uiColor: color)
            }
            if let background = attributes[.backgroundColor] as? UIColor {
                run.backgroundColor = Color(uiColor: background)
            }
            if attributes[.underlineStyle] != nil {
                run.underlineStyle = .single
            }
            if attributes[.strikethroughStyle] != nil {
                run.strikethroughStyle = .single
            }

            result.append(run)
        }

        return result
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
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            } else if phase.error == nil {
                                ProgressView()
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
