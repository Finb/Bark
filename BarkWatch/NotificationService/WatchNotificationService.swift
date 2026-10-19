//
//  WatchNotificationService.swift
//  Bark
//
//  Created by Jian Qin on 9/30/26.
//

import UserNotifications

/// The extension's principal class. The pipeline lives in `WatchNotificationDelivery`
/// so it can be exercised by tests without APNs driving it.
final class NotificationService: UNNotificationServiceExtension {
    private let delivery = WatchNotificationDelivery()

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        delivery.didReceive(request, withContentHandler: contentHandler)
    }

    override func serviceExtensionTimeWillExpire() { delivery.serviceExtensionTimeWillExpire() }
}
