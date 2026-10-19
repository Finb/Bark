//
//  PhoneCompatibility.swift
//  Bark
//
//  Created by Jian Qin on 9/30/26.
//

import Foundation
import UIKit

// Stand-ins for phone symbols used by the shared phone sources
// (Model/Algorithm.swift, Common/MarkdownParser.swift), scoped to watch targets.
// The phone files that define these are not compiled for watchOS. If the shared
// sources start using more symbols from those files, add watch versions here.

// Stands in for Common/BKColor.swift, whose colors load from the phone's asset
// catalog. Only the colors read by MarkdownParser.Configuration defaults are provided.
enum BKColor {
    enum grey {
        static let darken4 = UIColor.white
        static let lighten4 = UIColor.white.withAlphaComponent(0.12)
        static let base = UIColor.lightGray
    }
    enum blue {
        static let base = UIColor.cyan
    }
}

// Stands in for `localized` in Common/String+Extension.swift. The watch has no
// copy of Localizable.xcstrings, so the "image" key used by MarkdownParser falls back to "Image".
extension String {
    var localized: String {
        NSLocalizedString(self, value: self == "image" ? "Image" : self, comment: "")
    }
}

// Watch-only conformances added to phone types for the encryption settings UI.
extension Algorithm: CaseIterable {
    static let allCases: [Self] = [.aes128, .aes192, .aes256]
}

extension CryptoSettingFields: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.algorithm == rhs.algorithm && lhs.mode == rhs.mode && lhs.padding == rhs.padding
            && lhs.key == rhs.key && lhs.iv == rhs.iv
    }
}
