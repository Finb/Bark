import UserNotifications

final class NotificationService: UNNotificationServiceExtension {
    private let lock = NSLock()
    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?
    private var delivered = false

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler

        guard let content = request.content.mutableCopy() as? UNMutableNotificationContent else {
            deliver(request.content)
            return
        }
        bestAttemptContent = content

        Task {
            let prepared = await NotificationPipeline.prepare(content, identifier: request.identifier)
            publish(prepared)

            let withImage = await NotificationPipeline.attachImage(to: prepared)
            publish(withImage)

            let withIcon = await NotificationPipeline.attachIcon(to: withImage)
            publish(withIcon)

            deliver(withIcon)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        lock.lock()
        let content = bestAttemptContent
        lock.unlock()

        if let content {
            deliver(content)
        }
    }

    private func publish(_ content: UNMutableNotificationContent) {
        lock.lock()
        bestAttemptContent = content
        lock.unlock()
    }

    private func deliver(_ content: UNNotificationContent) {
        lock.lock()
        guard !delivered, let handler = contentHandler else {
            lock.unlock()
            return
        }
        delivered = true
        contentHandler = nil
        lock.unlock()

        handler(content)
    }
}
