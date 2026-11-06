import CoreText
import SwiftUI
import UIKit

enum WatchNotificationCategory {
    static let markdown = "myNotificationCategory"
}

/// MarkdownParser 的默认配色来自 iPhone 的资源目录，watch 包内没有这些颜色资源，
/// 这里给默认参数提供等效的系统颜色。
enum BKColor {
    enum grey {
        static let base = UIColor.lightGray
        static let darken4 = UIColor.white
        static let lighten4 = UIColor.darkGray
    }

    enum blue {
        static let base = UIColor.cyan
    }
}

enum MarkdownText {
    static var configuration: MarkdownParser.Configuration {
        MarkdownParser.Configuration(
            baseFont: UIFont.preferredFont(ofSize: 15),
            baseColor: .white,
            linkColor: .cyan,
            codeTextColor: .cyan,
            codeBackgroundColor: UIColor.white.withAlphaComponent(0.12),
            codeBlockTextColor: .white,
            quoteColor: .lightGray
        )
    }
    static func attributed(_ source: String) -> NSAttributedString {
        MarkdownParser(configuration: configuration).parse(source)
    }

    static func plain(_ source: String) -> String {
        attributed(source).string
    }

    static func swiftUIAttributed(_ source: String) -> AttributedString {
        swiftUIAttributed(from: attributed(source))
    }

    static func swiftUIAttributed(from text: NSAttributedString) -> AttributedString {
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
            if let link = attributes[.link] as? String, let url = URL(string: link) {
                run.link = url
            } else if let url = attributes[.link] as? URL {
                run.link = url
            }

            result.append(run)
        }

        return result
    }
}
