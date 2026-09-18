//
//  CodeHighlighter.swift
//  Bark
//
//  Created by huangfeng on 8/25/26.
//  Copyright © 2026 Fin. All rights reserved.
//

import UIKit

enum CodeHighlighter {
    static func highlight(_ text: String, font: UIFont = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)) -> NSAttributedString {
        let attributed = NSMutableAttributedString(
            string: text,
            attributes: [
                .font: font,
                .foregroundColor: UIColor.label
            ]
        )
        let fullRange = NSRange(location: 0, length: (text as NSString).length)

        func ranges(ofPattern pattern: String) -> [NSRange] {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
            return regex.matches(in: text, range: fullRange).map(\.range)
        }

        // 引号字符串（URL、参数值）→ 藏蓝
        let quotedRanges = ranges(ofPattern: "\"[^\"]*\"|'[^']*'")
        for quotedRange in quotedRanges {
            attributed.addAttribute(.foregroundColor, value: Self.stringColor, range: quotedRange)
        }

        // curl 命令 → 紫
        for item in ranges(ofPattern: "^curl") {
            attributed.addAttribute(.foregroundColor, value: Self.commandColor, range: item)
        }

        // 参数标志（-X / -d / -H 等）→ 红，跳过引号内内容
        for flagRange in ranges(ofPattern: "(?<=\\s)-{1,2}[A-Za-z][A-Za-z-]*") {
            guard !quotedRanges.contains(where: { NSIntersectionRange($0, flagRange).length > 0 }) else { continue }
            attributed.addAttribute(.foregroundColor, value: Self.flagColor, range: flagRange)
        }

        return attributed
    }

    private static let commandColor = UIColor(named: "command_color")!
    private static let flagColor = UIColor(named: "flag_color")!
    private static let stringColor = UIColor(named: "string_color")!
}
