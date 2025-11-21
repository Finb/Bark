//
//  MarkdownParser.swift
//  Bark
//
//  Created by huangfeng on 2025/11/20.
//  Copyright © 2025 Fin. All rights reserved.
//

import Markdown
import UIKit

class MarkdownParser {
    struct Configuration {
        let baseFont: UIFont
        let baseColor: UIColor
        let linkColor: UIColor
        let codeTextColor: UIColor
        let codeBackgroundColor: UIColor
        let codeBlockTextColor: UIColor
        let quoteColor: UIColor
        
        init(
            baseFont: UIFont = UIFont.preferredFont(ofSize: 14),
            baseColor: UIColor = BKColor.grey.darken4,
            linkColor: UIColor = BKColor.blue.base,
            codeTextColor: UIColor = BKColor.blue.base,
            codeBackgroundColor: UIColor = BKColor.grey.lighten4,
            codeBlockTextColor: UIColor = BKColor.grey.darken4,
            quoteColor: UIColor = BKColor.grey.base
        ) {
            self.baseFont = baseFont
            self.baseColor = baseColor
            self.linkColor = linkColor
            self.codeTextColor = codeTextColor
            self.codeBackgroundColor = codeBackgroundColor
            self.codeBlockTextColor = codeBlockTextColor
            self.quoteColor = quoteColor
        }
    }
    
    private let configuration: Configuration
    
    init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }
    
    func parse(_ markdown: String) -> NSAttributedString {
        let document = Document(parsing: markdown)
        var walker = AttributedStringWalker(configuration: configuration)
        walker.visit(document)
        return walker.attributedString
    }
}

private struct AttributedStringWalker: MarkupWalker {
    let configuration: MarkdownParser.Configuration
    let attributedString = NSMutableAttributedString()
    
    var attributes: [NSAttributedString.Key: Any] = [:]
    
    enum ListType {
        case ordered
        case unordered
    }
    var listStack: [(type: ListType, index: Int)] = []
    
    init(configuration: MarkdownParser.Configuration) {
        self.configuration = configuration
        self.attributes = [
            .font: configuration.baseFont,
            .foregroundColor: configuration.baseColor
        ]
    }
    
    mutating func visitDocument(_ document: Document) {
        for child in document.children {
            visit(child)
        }
    }
    
    /// 段落
    mutating func visitParagraph(_ paragraph: Paragraph) {
        // 如果是在列表项中，段落不需要额外的换行
        // 结尾已经有两个换行也不加了
        if attributedString.length > 0, !(paragraph.parent is ListItem), !attributedString.string.hasSuffix("\n\n") {
            attributedString.append(NSAttributedString(string: "\n\n", attributes: attributes))
        }
        
        for child in paragraph.children {
            visit(child)
        }
    }
    
    /// 文本
    mutating func visitText(_ text: Text) {
        attributedString.append(NSAttributedString(string: text.string, attributes: attributes))
    }
    
    /// 加粗
    mutating func visitStrong(_ strong: Strong) {
        let originalAttributes = attributes
        defer { attributes = originalAttributes }
        
        let originalFont = attributes[.font] as? UIFont ?? configuration.baseFont
        attributes[.font] = originalFont.bold()
        
        for child in strong.children {
            visit(child)
        }
    }
    
    /// 斜体
    mutating func visitEmphasis(_ emphasis: Emphasis) {
        let originalAttributes = attributes
        defer { attributes = originalAttributes }
        
        let originalFont = attributes[.font] as? UIFont ?? configuration.baseFont
        attributes[.font] = originalFont.italic()
        
        for child in emphasis.children {
            visit(child)
        }
    }

    /// 删除线
    mutating func visitStrikethrough(_ strikethrough: Strikethrough) {
        let originalAttributes = attributes
        defer { attributes = originalAttributes }
        
        attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
        
        for child in strikethrough.children {
            visit(child)
        }
    }
    
    /// 链接
    mutating func visitLink(_ link: Link) {
        let originalAttributes = attributes
        defer { attributes = originalAttributes }
        
        attributes[.foregroundColor] = configuration.linkColor
        attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        if let destination = link.destination {
            attributes[.link] = destination
        }
        
        for child in link.children {
            visit(child)
        }
    }
    
    /// 行内代码
    mutating func visitInlineCode(_ inlineCode: InlineCode) {
        var currentAttributes = attributes
        
        currentAttributes[.font] = UIFont.monospacedSystemFont(ofSize: configuration.baseFont.pointSize, weight: .regular)
        currentAttributes[.foregroundColor] = configuration.codeTextColor
        currentAttributes[.backgroundColor] = configuration.codeBackgroundColor
        
        attributedString.append(NSAttributedString(string: inlineCode.code, attributes: currentAttributes))
    }
    
    /// 代码块
    mutating func visitCodeBlock(_ codeBlock: CodeBlock) {
        if attributedString.length > 0, !attributedString.string.hasSuffix("\n\n") {
            attributedString.append(NSAttributedString(string: "\n\n", attributes: attributes))
        }
        
        var currentAttributes = attributes
        
        currentAttributes[.font] = UIFont.monospacedSystemFont(ofSize: configuration.baseFont.pointSize, weight: .regular)
        currentAttributes[.foregroundColor] = configuration.codeBlockTextColor
        currentAttributes[.backgroundColor] = configuration.codeBackgroundColor
        
        attributedString.append(NSAttributedString(string: codeBlock.code, attributes: currentAttributes))
        
        attributedString.append(NSAttributedString(string: "\n", attributes: [.font: configuration.baseFont]))
    }

    /// 标题
    mutating func visitHeading(_ heading: Heading) {
        if attributedString.length > 0, !attributedString.string.hasSuffix("\n\n") {
            attributedString.append(NSAttributedString(string: "\n\n", attributes: attributes))
        }
        
        let originalAttributes = attributes
        defer { attributes = originalAttributes }
        
        let level = heading.level
        var size = configuration.baseFont.pointSize
        var weight = UIFont.Weight.bold
        
        switch level {
        case 1: size += 6; weight = .heavy
        case 2: size += 4; weight = .bold
        case 3: size += 2; weight = .semibold
        default: break
        }
        
        attributes[.font] = UIFont.systemFont(ofSize: size, weight: weight)
        
        for child in heading.children {
            visit(child)
        }
    }
    
    /// 引用
    mutating func visitBlockQuote(_ blockQuote: BlockQuote) {
        if attributedString.length > 0 {
            attributedString.append(NSAttributedString(string: "\n", attributes: attributes))
        }
        
        let originalAttributes = attributes
        defer { attributes = originalAttributes }
        
        attributes[.foregroundColor] = configuration.quoteColor
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = 10
        paragraphStyle.headIndent = 10
        attributes[.paragraphStyle] = paragraphStyle
        
        for child in blockQuote.children {
            visit(child)
        }
    }
    
    /// 有序列表
    mutating func visitOrderedList(_ orderedList: OrderedList) {
        if attributedString.length > 0 && listStack.isEmpty {
            attributedString.append(NSAttributedString(string: "\n", attributes: attributes))
        }
        
        listStack.append((type: .ordered, index: Int(orderedList.startIndex)))
        
        for child in orderedList.children {
            visit(child)
        }
        
        listStack.removeLast()
    }
    
    /// 无序列表
    mutating func visitUnorderedList(_ unorderedList: UnorderedList) {
        if attributedString.length > 0 && listStack.isEmpty {
            attributedString.append(NSAttributedString(string: "\n", attributes: attributes))
        }
        
        listStack.append((type: .unordered, index: 0))
        
        for child in unorderedList.children {
            visit(child)
        }
        
        listStack.removeLast()
    }
    
    /// 列表项
    mutating func visitListItem(_ listItem: ListItem) {
        let originalAttributes = attributes
        defer { attributes = originalAttributes }
        
        let level = CGFloat(listStack.count - 1)
        let indent: CGFloat = 20
        let baseIndent = level * indent
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = baseIndent
        paragraphStyle.headIndent = baseIndent + indent
        paragraphStyle.paragraphSpacingBefore = 4
        attributes[.paragraphStyle] = paragraphStyle
        
        var prefix = ""
        if let last = listStack.last {
            if last.type == .ordered {
                prefix = "\(last.index). "
            } else if listItem.checkbox == nil {
                prefix = "• "
            }
        }
        if attributedString.length > 0 {
            attributedString.append(NSAttributedString(string: "\n", attributes: attributes))
        }
        attributedString.append(NSAttributedString(string: "\(prefix)", attributes: attributes))
        
        if let checkbox = listItem.checkbox {
            let imageName = checkbox == .checked ? "checkmark.square" : "square"
            let font = attributes[.font] as? UIFont ?? configuration.baseFont
            let color = attributes[.foregroundColor] as? UIColor ?? configuration.baseColor
            
            let symbolConfiguration = UIImage.SymbolConfiguration(font: font)
            if let image = UIImage(systemName: imageName, withConfiguration: symbolConfiguration)?.withTintColor(color, renderingMode: .alwaysOriginal) {
                let attachment = NSTextAttachment()
                attachment.image = image
                let y = (font.capHeight - image.size.height).rounded() / 2
                attachment.bounds = CGRect(x: 0, y: y, width: image.size.width, height: image.size.height)
                
                attributedString.append(NSAttributedString(attachment: attachment))
                attributedString.append(NSAttributedString(string: " ", attributes: attributes))
            } else {
                let text = checkbox == .checked ? "☑ " : "☐ "
                attributedString.append(NSAttributedString(string: text, attributes: attributes))
            }
        }
        
        for child in listItem.children {
            visit(child)
        }
        
        // 更新 listStack 索引
        if !listStack.isEmpty {
            var last = listStack[listStack.count - 1]
            if last.type == .ordered {
                last.index += 1
                listStack[listStack.count - 1] = last
            }
        }
    }

    /// 软换行渲染为空格
    mutating func visitSoftBreak(_ softBreak: SoftBreak) {
        attributedString.append(NSAttributedString(string: " ", attributes: attributes))
    }

    /// 硬换行
    mutating func visitLineBreak(_ lineBreak: LineBreak) {
        attributedString.append(NSAttributedString(string: "\n", attributes: attributes))
    }
}
