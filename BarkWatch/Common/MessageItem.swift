import Foundation

struct MessageItem: Identifiable, Equatable {
    let id: String
    let title: String?
    let subtitle: String?
    let markdown: String?
    let body: String?
    let url: String?
    let image: String?
    let group: String
    let createDate: Date

    init(_ message: WatchMessage) {
        id = message.id
        title = message.title
        subtitle = message.subtitle
        markdown = message.markdown
        body = message.body
        url = message.url
        image = message.image
        group = message.group
        createDate = message.createDate
    }
}
