//
//  WatchConstants.swift
//  Bark
//
//  Created by Jian Qin on 10/10/26.
//

import os

/// Identifiers shared by the watch app and its extensions.
///
/// The keychain group must match the `.entitlements` files and the
/// `BarkKeychainAccessGroup` Info.plist entries; update them together when the
/// bundle identifier changes.
nonisolated enum WatchConstants {
    static let bundleIdentifier = "me.fin.BarkWatch"
    static let appGroupIdentifier = "group.bark"
}

nonisolated extension Logger {
    /// Opening links from the Last message page and the notification interface.
    static let links = Logger(subsystem: WatchConstants.bundleIdentifier, category: "Links")
    /// Notification permission, the device token, and server registration.
    static let registration = Logger(subsystem: WatchConstants.bundleIdentifier, category: "Registration")
}
