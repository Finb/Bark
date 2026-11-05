import Foundation
import SwiftData

@Model
final class WatchGroup {
    @Attribute(.unique) var key: String

    var latestDate: Date

    init(key: String, latestDate: Date) {
        self.key = key
        self.latestDate = latestDate
    }
}
