# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Bark is an iOS push notification tool app that allows users to send custom push notifications to their devices via HTTP requests. It leverages Apple Push Notification service (APNs) and supports advanced iOS notification features like grouping, custom icons/sounds, time-sensitive notifications, critical alerts, and end-to-end encryption.

## Development Commands

### Dependencies
```bash
# Install CocoaPods dependencies
pod install

# Always work with the workspace, not the project
# Open: Bark.xcworkspace
```

### Testing
```bash
# Run tests via fastlane
bundle exec fastlane tests

# Run tests via xcodebuild
xcodebuild test -workspace Bark.xcworkspace -scheme Bark
```

### Building
```bash
# Build the app
xcodebuild -workspace Bark.xcworkspace -scheme Bark build

# Build for TestFlight (requires proper certificates and environment variables)
bundle exec fastlane beta
```

## Architecture

### Core Components

**Main App Target (Bark/)**
- Entry point: `AppDelegate.swift` - handles app lifecycle, APNs registration, Realm setup
- `AppDelegate+Realm.swift` - Realm database initialization and migration logic
- Realm schema version: 17 (see `RealmConfiguration.swift`)

**Notification Extensions**
1. `NotificationServiceExtension/` - UNNotificationServiceExtension that processes incoming notifications
   - `NotificationService.swift` - orchestrates notification processing through a pipeline of processors
   - `Processor/` directory contains specialized processors that run sequentially:
     - `CiphertextProcessor` - decrypts encrypted push content (must run first)
     - `MarkdownProcessor` - renders markdown in notification body
     - `LevelProcessor` - handles notification levels (active/timeSensitive/passive/critical)
     - `BadgeProcessor` - manages app badge count
     - `AutoCopyProcessor` - auto-copies content to clipboard
     - `ArchiveProcessor` - saves message to Realm database
     - `MuteProcessor` - handles group muting
     - `CallProcessor` - plays repeating sound for 30 seconds
     - `ImageProcessor` - downloads and attaches images
     - `IconProcessor` - sets custom notification icon (iOS 15+, runs last as it may timeout)

2. `notificationContentExtension/` - custom notification UI
   - `NotificationViewController.swift` - displays custom content in notification

### Project Structure

**Model/** - Data models
- `Message.swift` - Realm object for stored notifications (properties: title, subtitle, body, bodyType, url, image, group, createDate)
- `MessageItemModel.swift` - view model for message display
- `Algorithm.swift` - encryption/decryption algorithms for end-to-end encryption

**Controller/** - View controllers using MVVM pattern
- Suffix `ViewController` for views, `ViewModel` for view models
- Key screens:
  - `HomeViewController` + `HomeViewModel` - main screen showing tutorial and test URL
  - `MessageListViewController` + `MessageListViewModel` - notification history grouped by date/group
  - `ServerListViewController` + `ServerListViewModel` - manage multiple push servers
  - `CryptoSettingController` + `CryptoSettingViewModel` - configure encryption keys
  - `SoundsViewController` + `SoundsViewModel` - manage custom notification sounds

**View/** - Reusable UI components
- Custom cells, buttons, text views
- `View/MessageList/` - specialized views for message display with markdown support

**Common/** - Shared utilities and managers
- `Client.swift` - singleton managing app state, device token, current tab navigation
- `ServerManager.swift` - manages multiple push servers (default: https://api.day.app)
- `BarkSettings.swift` - UserDefaults wrapper for persistent settings using DefaultsKit
- `RealmConfiguration.swift` - shared Realm configuration between app and extensions
- `Moya/` - Network layer using Moya + RxSwift
  - `BarkApi.swift` - API endpoints (ping, register)
  - `BarkTargetType.swift` - base target type
  - `Observable+Extension.swift` - Rx helpers

### Key Technologies

- **RxSwift/RxCocoa** - Reactive programming for data binding and async operations
- **Realm** - Local database for message persistence (shared between app and extensions via App Groups)
- **Moya** - Network abstraction layer over Alamofire
- **Material/SnapKit** - UI framework and Auto Layout DSL
- **CryptoSwift** - Encryption for secure push notifications
- **Kingfisher** - Image downloading and caching

### Data Flow

1. **Device Registration**: App requests APNs token → sends to server via `/register` endpoint → server stores device token with user's key
2. **Receiving Push**: Server sends push → APNs delivers to device → `NotificationServiceExtension` processes through processor pipeline → notification displayed
3. **Message Storage**: `ArchiveProcessor` saves to Realm → Darwin notification sent to main app → main app refreshes message list
4. **Encryption Flow**: If ciphertext parameter present → `CiphertextProcessor` decrypts using locally stored key → continues normal processing

### App Groups & Data Sharing

The app uses App Groups to share data between the main app and notification extensions:
- Realm database at shared Documents directory
- Settings via `BarkSettings` (DefaultsKit)
- Darwin notifications for cross-process communication (e.g., "com.bark.newmessage")

### Server Architecture

Users can configure multiple push servers (`ServerManager`):
- Default server: `https://api.day.app`
- Each server has: id, address, key, state, optional name
- Old single-server data (pre-v1.2.6) is automatically migrated to new multi-server format

### Notification Processing Pipeline

Order matters - processors run sequentially in `NotificationService.swift`:
1. Ciphertext decryption (must be first - may contain all push data)
2. Content processing (markdown, level, badge, autoCopy)
3. Database archiving
4. Mute checking
5. Sound effects (call mode)
6. Media attachments (image, icon - icon last as it may timeout)

## Important Notes

- Always open `Bark.xcworkspace`, never `Bark.xcproject`
- Minimum iOS deployment target: 13.0
- Realm schema migrations are handled in `RealmConfiguration.swift` - increment `schemaVersion` when changing Message model
- The app supports both iPhone and iPad (with split view controller on iPad)
- Localization is managed via `Localizable.xcstrings`
- Custom notification sounds are in `Sounds/` directory
- The app uses Material Design components for UI
- Code signing is disabled for Pods (see Podfile post_install)

## Testing

Tests are located in `BarkTests/` directory. The CI runs tests on every push to master via GitHub Actions (`.github/workflows/tests.yaml`).
