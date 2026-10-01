# BarkWatch server setup

With Git and Go 1.26 or later installed, run the supplied [build script](scripts/build-watch-server.sh) from the Bark repository root. It downloads a pinned upstream server revision, applies [watch-server.patch](scripts/watch-server.patch), and builds `build/watch-server/bark-server`. The generated source, executable, and server data stay under the ignored `build/` directory.

```sh
./BarkWatch/scripts/build-watch-server.sh
```

Obtain an Apple push authentication key (`.p8`), its key identifier, and your team identifier from the developer account used to sign BarkWatch. The key must authorize the watch application and the chosen push environment. Replace the example key path and identifiers below with your own values, then run these commands from the Bark repository root:

```sh
export BARK_APNS_KEY_FILE='/absolute/path/to/AuthKey_YOUR_KEY_ID.p8'
export BARK_APNS_KEY_ID='YOUR_KEY_ID'
export BARK_APNS_TEAM_ID='YOUR_TEAM_ID'
export BARK_APNS_TOPIC='com.sebersta.BarkWatchPrototype'
export BARK_APNS_ENVIRONMENT='development'
./build/watch-server/bark-server --addr 0.0.0.0:8080 --data ./build/watch-server/data
```

`BARK_APNS_TOPIC` must match the **BarkWatch application** bundle identifier in Xcode. If you changed it, update the value above. The key identifier belongs to the `.p8` key; the team identifier belongs to the watch's signing account. Use `development` for this checkout's development-signed watch build and `production` for a build signed with the production push entitlement. The environment selects Apple's sandbox or production endpoint; it does not change how the app is signed.

To make the changes in your own upstream checkout instead, add `"os"` to the imports in `apns/apns.go` and replace the existing constants for `topic`, `keyID`, and `teamID` with:

```go
const PayloadMaximum = 4096

var (
    topic  = os.Getenv("BARK_APNS_TOPIC")
    keyID  = os.Getenv("BARK_APNS_KEY_ID")
    teamID = os.Getenv("BARK_APNS_TEAM_ID")
)
```

Inside `ReCreateAPNS`, replace the existing `token.AuthKeyFromBytes(...)` declaration with the following block, keeping the existing error check immediately after it:

```go
if topic == "" || keyID == "" || teamID == "" {
    logger.Fatal("BARK_APNS_TOPIC, BARK_APNS_KEY_ID and BARK_APNS_TEAM_ID are required")
}
host := apns2.HostDevelopment
switch os.Getenv("BARK_APNS_ENVIRONMENT") {
case "development":
case "production":
    host = apns2.HostProduction
default:
    logger.Fatal("BARK_APNS_ENVIRONMENT must be development or production")
}
authKey, err := token.AuthKeyFromFile(os.Getenv("BARK_APNS_KEY_FILE"))
```

In the same function, change the `apns2.Client` field from `Host: apns2.HostProduction` to `Host: host`. Its existing `Token` fields already reference `authKey`, `keyID`, and `teamID`.

In `route_push.go`, find the `case "sound"` branch and change its condition to `if val == "default" || strings.HasSuffix(val, ".caf")`. This preserves the watch's system sound name instead of turning it into `default.caf`.

For silent deletion, find `Push` in `apns/apns.go`. Add `priority := apns2.PriorityHigh` beside `pushType := apns2.PushTypeAlert`, set `priority = apns2.PriorityLow` inside the existing `if msg.IsDelete()` branch, and add `Priority: priority` to the `apns2.Notification` sent by `client.Push`. The existing deletion branch already sets the background push type and `content-available`, and omits alert text and sound. Keep the existing collapse identifier and custom payload handling. If your Go toolchain rejects `fmt.Errorf(resp.Reason)`, change it to `fmt.Errorf("%s", resp.Reason)`.

Build your manually modified checkout with `go build -o bark-server .`, export the five `BARK_APNS_...` values shown above, and launch it with `./bark-server --addr 0.0.0.0:8080 --data ./data`. Restart an already running server after rebuilding or changing its configuration.

On the watch, add `http://YOUR_MAC_LOCAL_ADDRESS:8080`, replacing the address with the Mac's reachable local network address; `0.0.0.0` is only the server's listening address. Wait for registration, send a test notification, and confirm it arrives on the watch. This configuration targets the watch; serving differently signed phone and watch apps together requires separate server instances or routing by app identity.

The [notification test sender](scripts/send-watch-tests.py) covers text, Markdown, grouping, alert levels, sound, images, icons, links, replacement, archive expiration, and silent deletion. Preview all test expectations without sending anything:

```sh
python3 BarkWatch/scripts/send-watch-tests.py --dry-run
```

To send selected tests, supply your server's base address and the registered key displayed by the watch. `W03` checks Markdown; `W31` automatically includes the alert and first deletion needed to test repeated silent deletion. Requests are 15 seconds apart by default; use `--interval 20` to change the delay. Each run uses fresh identifiers, so replacement and deletion affect only that run's test notifications. Omit `--only` to send every case.

```sh
python3 BarkWatch/scripts/send-watch-tests.py \
  --server http://YOUR_MAC_LOCAL_ADDRESS:8080 \
  --key YOUR_WATCH_DEVICE_KEY --only W03 W31
```

You can supply `BARK_SERVER_URL` and `BARK_DEVICE_KEY` as environment variables instead. Server acceptance does not confirm delivery or correct rendering; check the notification, latest-message view, and complication on the watch. Run the sender's local automated check with `python3 BarkWatch/scripts/test_send_watch_tests.py`; it uses a temporary local server and never contacts Apple.
