import Foundation
import SwiftData

@Model
final class WatchMessage {
    #Index<WatchMessage>([\.id], [\.createDate], [\.group, \.createDate])

    var id: String
    var title: String?
    var subtitle: String?
    var body: String?
    var url: String?
    var image: String?
    var group: String
    var createDate: Date
    var expireDate: Date?

    init(
        id: String,
        title: String?,
        subtitle: String?,
        body: String?,
        url: String?,
        image: String?,
        group: String,
        createDate: Date,
        expireDate: Date?
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.body = body
        self.url = url
        self.image = image
        self.group = group
        self.createDate = createDate
        self.expireDate = expireDate
    }
}
