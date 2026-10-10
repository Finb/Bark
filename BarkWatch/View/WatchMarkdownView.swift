//
//  WatchMarkdownView.swift
//  Bark
//
//  Created by Jian Qin on 9/30/26.
//


import SwiftUI
import UIKit

// Render the phone parser's attributed text, retaining paragraph indentation that
// SwiftUI Text does not carry over from NSParagraphStyle. Used by both the app and
// the notification interface.
struct WatchMarkdownView: View {
    let source: String
    /// Handles tapped web links. When nil, links go to the environment's `openURL`,
    /// which the app routes to a browser session. The notification interface can't
    /// open a browser, so it passes its own handler.
    var openLink: ((URL) -> Void)?
    @ScaledMetric(relativeTo: .body) private var fontSize = 14
    @Environment(\.openURL) private var openURL

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
        // Only web links are allowed; anything else is discarded.
        .environment(\.openURL, OpenURLAction { [openURL, openLink] url in
            guard WatchNotification.validatedWebURL(url.absoluteString) != nil else { return .discarded }
            if let openLink { openLink(url) } else { openURL(url) }
            return .handled
        })
    }
}

struct WatchMarkdownParagraph: Identifiable {
    let id: Int
    var text: AttributedString
    let marker: AttributedString?
    let markerWidth: CGFloat
    let indent: CGFloat
    let spaceBefore: CGFloat
    let codeBlock: Int?
    var isCode: Bool { codeBlock != nil }

    static func paragraphs(from source: NSAttributedString) -> [Self] {
        let safeText = NSMutableAttributedString(attributedString: source)
        source.enumerateAttribute(.link, in: NSRange(location: 0, length: source.length)) { value, range, _ in
            guard let value else { return }
            let address = (value as? URL)?.absoluteString ?? value as? String
            if let url = WatchNotification.validatedWebURL(address) {
                safeText.addAttribute(.link, value: url, range: range)
            } else {
                safeText.removeAttribute(.link, range: range)
            }
        }
        var result: [Self] = []
        var offset = 0
        var blankSpace: CGFloat = 0
        let string = safeText.string as NSString
        while offset < safeText.length {
            var blockRange = NSRange()
            let codeBlock = safeText.attribute(.markdownCodeBlock, at: offset, effectiveRange: &blockRange) as? Int
            let newline = string.range(of: "\n", range: NSRange(location: offset, length: safeText.length - offset))
            var range = codeBlock != nil ? blockRange : NSRange(location: offset,
                length: (newline.location == NSNotFound ? safeText.length : newline.location) - offset)
            offset = NSMaxRange(range) + (codeBlock == nil && newline.location != NSNotFound ? 1 : 0)
            if codeBlock != nil, string.substring(with: range).hasSuffix("\n") { range.length -= 1 }
            if range.length == 0 {
                if !result.isEmpty { blankSpace += 10 }
                continue
            }
            let slice = safeText.attributedSubstring(from: range)
            let style = slice.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
            var markerRange = NSRange()
            let hasMarker = slice.attribute(.markdownListMarker, at: 0, effectiveRange: &markerRange) as? Bool == true
            let markerLength = hasMarker ? markerRange.length : 0
            let indent = hasMarker ? style?.firstLineHeadIndent ?? 0 : style?.headIndent ?? 0
            let markerWidth = hasMarker ? max(0, (style?.headIndent ?? 0) - indent) : 0
            let marker = hasMarker ? AttributedString(slice.attributedSubstring(from: markerRange)) : nil
            let text = AttributedString(slice.attributedSubstring(from:
                NSRange(location: markerLength, length: slice.length - markerLength)))
            result.append(Self(id: range.location, text: text, marker: marker, markerWidth: markerWidth,
                               indent: indent, spaceBefore: blankSpace + (style?.paragraphSpacingBefore ?? 0),
                               codeBlock: codeBlock))
            blankSpace = 0
        }
        return result
    }
}

#Preview("Phone Markdown on watch") {
    ScrollView {
        WatchMarkdownView(source: """
        # Training
        **Strong**, *emphasis*, ~~removed~~ and `code`.

        > A quoted paragraph.

        3. First item
        4. Second item
           - Nested item

        - [x] Completed
        - [ ] Pending

        ```swift
        let distance = 42
        print(distance)
        ```

        [Bark](https://bark.day.app) and ![Photo](https://example.com/photo.png)
        """).padding()
    }
}
