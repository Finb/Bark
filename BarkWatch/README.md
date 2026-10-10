
BarkWatch

A standalone watch application prototype for watchOS 10 or later. Communication with the phone app is not yet implemented. BarkWatch shares the unchanged iOS sources `Model/Algorithm.swift`, `Common/MarkdownParser.swift`, and `Common/UIFont+Extension.swift`. Watch-specific adaptations live in `BarkWatch/Common`.

**BarkWatch cannot use the official Bark server because its push configuration targets the official phone app.** Use a custom Bark server with your Apple signing credentials, the watch's bundle identifier (`com.sebersta.BarkWatchPrototype` in this checkout).

## Shared iOS Code
The watch targets compile three iOS files. Change to these files can break the watch build.

| iOS file | Watch relies on |
| --- | --- |
| `Model/Algorithm.swift` | `Algorithm` (`modes`, `keyLength`), `CryptoSettingFields`, and all four stored properties of `AESCryptoModel` (`key`, `mode`, `padding`, `aes`), which `AESCryptoModel(watchFields:)` assigns |
| `Common/MarkdownParser.swift` | `MarkdownParser.Configuration`; `WatchMarkdownParser` identifies code blocks by monospaced font plus `codeBlockTextColor` plus a background color, and task-list checkboxes as text attachments |
| `Common/UIFont+Extension.swift` | `UIFont.preferredFont(ofSize:weight:)` used by `MarkdownParser` |

### PhoneCompatibility.swift
`Algorithm.swift` and `MarkdownParser.swift` use code from three other iOS files. The watch App does not compile those files, so `BarkWatch/Common/PhoneCompatibility.swift` contains copies of just the parts that are used:

| iOS file | Why  BarkWatch needs a copy |
| --- | --- |
| `Common/BKColor.swift` | `MarkdownParser` uses four `BKColor` colors as defaults. The iOS app loads them from its asset catalog, which the watch does not have, so the watch defines them as fixed colors manually. |
| `Common/Error+Extension.swift` | `Algorithm.swift` throws plain strings (`throw "Invalid Mode"`). This only compiles because of `extension String: Error {}`, which the watch copies. |
| `Common/String+Extension.swift` | Both files call `.localized`. The watch has its own `.localized` without the iOS app's string catalog. |

The tests encryptedNotificationsMatchPhoneWireFormat and markdownUsesPhoneParserForFormattingAndNotificationFallback in BarkWatch/Tests/NotificationTests.swift check that the watch's encryption and Markdown output still match the iOS.

## Request Parameters Availability
| Parameter | Watch app |
| --- | --- |
| `title`, `subtitle`, `body` | Supported |
| `markdown` | Supported |
| `ciphertext`, `iv` | Same encryption model; configure the watch's own key. |
| `level=active`, `passive`, `timeSensitive` | Supported |
| `level=critical`, `volume` | Implemented, not tested. |
| `sound` | Custom sound unavailable. `silent` supported. |
| `image`, `icon` | Supported |
| `url` | Explicit Open Link button. |
| `group` | Thread metadata and complication filtering; no group muting. |
| `id` | Supported |
| `isArchive`, `ttl` | Supported |
| `badge`, `call` | Unavailable |
| `autocopy`, `automaticallycopy`, `copy` | Unavailable |
| `action` | Unavailable |
| `delete` | Supported |

Opening web links requires an extra handoff on the watch. The notification interface cannot present the browser directly: tapping **Open link** or a Markdown link passes the selected address and launches the app. BarkWatch waits until it is active before presenting the page. BarkWatch uses `WebAuthenticationSession` to display web pages. The app requests an ephemeral session so cookies are not shared with other sessions. Only links using `http` or `https` are accepted; application links and addresses containing embedded login credentials are rejected.

## Widget
BarkWatch supports a rectangular widget that displays the latest notification. The background color of the complication changes depending on the notification `level`.
