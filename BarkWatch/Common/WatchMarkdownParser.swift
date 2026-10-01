import Markdown
import UIKit

extension NSAttributedString.Key {
    static let markdownCodeBlock = NSAttributedString.Key("bark.markdown.codeBlock")
    static let markdownListMarker = NSAttributedString.Key("bark.markdown.listMarker")
}

// Retain the phone parser; adapt attachments and paragraph metadata for SwiftUI.
enum WatchMarkdownParser {
    static func parse(_ source: String, configuration: MarkdownParser.Configuration = .default) -> NSAttributedString {
        let text = NSMutableAttributedString(attributedString: MarkdownParser(configuration: configuration).parse(source))
        var checkboxes = CheckboxWalker()
        checkboxes.visit(Document(parsing: source))
        var attachments: [NSRange] = []
        text.enumerateAttribute(.attachment, in: NSRange(location: 0, length: text.length)) { value, range, _ in
            if value != nil { attachments.append(range) }
        }
        for (range, checked) in zip(attachments, checkboxes.checked).reversed() {
            let attributes = text.attributes(at: NSMaxRange(range), effectiveRange: nil)
            text.replaceCharacters(in: range, with: NSAttributedString(string: checked ? "☑" : "☐", attributes: attributes))
        }
        // The phone distinguishes block code from inline code through its text color.
        var codeRanges: [NSRange] = []
        text.enumerateAttributes(in: NSRange(location: 0, length: text.length)) { attributes, range, _ in
            if (attributes[.font] as? UIFont)?.fontDescriptor.symbolicTraits.contains(.traitMonoSpace) == true,
               (attributes[.foregroundColor] as? UIColor) == configuration.codeBlockTextColor,
               attributes[.backgroundColor] != nil {
                codeRanges.append(range)
            }
        }
        for range in codeRanges { text.addAttribute(.markdownCodeBlock, value: range.location, range: range) }
        let string = text.string as NSString
        var offset = 0
        while offset < text.length {
            let line = string.lineRange(for: NSRange(location: offset, length: 0))
            offset = NSMaxRange(line)
            guard text.attribute(.markdownCodeBlock, at: line.location, effectiveRange: nil) == nil,
                  let style = text.attribute(.paragraphStyle, at: line.location, effectiveRange: nil) as? NSParagraphStyle,
                  style.headIndent > style.firstLineHeadIndent else { continue }
            let prefix = string.substring(with: line)
            if let marker = prefix.range(of: "^(?:\\d+\\. (?:[☑☐] )?|\u{2022} |[☑☐] )", options: .regularExpression) {
                let range = NSRange(marker, in: prefix)
                text.addAttribute(.markdownListMarker, value: true,
                                  range: NSRange(location: line.location, length: range.length))
            }
        }
        return text
    }

    private struct CheckboxWalker: MarkupWalker {
        var checked: [Bool] = []
        mutating func visitListItem(_ item: ListItem) {
            if let checkbox = item.checkbox { checked.append(checkbox == .checked) }
            defaultVisit(item)
        }
    }
}
