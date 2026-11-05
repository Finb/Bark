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
}
