import Foundation
import UIKit

// Dependencies expected by the unchanged phone sources, scoped to watch targets.
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

extension String: @retroactive Error {}

extension String {
    var localized: String {
        NSLocalizedString(self, value: self == "image" ? "Image" : self, comment: "")
    }
}

extension Algorithm: CaseIterable {
    static let allCases: [Self] = [.aes128, .aes192, .aes256]
}

extension CryptoSettingFields: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.algorithm == rhs.algorithm && lhs.mode == rhs.mode && lhs.padding == rhs.padding
            && lhs.key == rhs.key && lhs.iv == rhs.iv
    }
}
