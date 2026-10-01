# BarkWatch

A standalone watch application prototype for watchOS 10 or later. Communication with the phone app is not yet implemented. BarkWatch shares the unchanged phone sources `Model/Algorithm.swift`, `Common/MarkdownParser.swift`, and `Common/UIFont+Extension.swift`. Watch-specific adaptations live in `BarkWatch/Common`.

**BarkWatch cannot use the official Bark server because its push configuration targets the official phone app.** Use a custom Bark server with your Apple signing credentials, the watch's bundle identifier (`com.sebersta.BarkWatchPrototype` in this checkout), and the matching development or production push environment. See [ServerSetup.md](ServerSetup.md) for server modification, configuration, and launch instructions.

## Request Parameters
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
BarkWatch support a rectangular widget that displays the latest notification. The background color of the complication changes depends on notification `level`.
