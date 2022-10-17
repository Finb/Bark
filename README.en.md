# Bark

![Bark](https://raw.githubusercontent.com/Finb/Bark/master/Bark/Assets.xcassets/AppIcon.appiconset/Icon-60%403x.png)

[Bark](https://github.com/Finb/Bark) is an open-source push notifications app that respects your privacy. You can host your own server, or use the free public service, to send real-time alerts to your iPhone. Everything stays between you and your server (plus Apple). Bark supports webhooks and a simple HTTP API.

This repository contains the source code for the iOS app. For the backend, [bark-server](https://github.com/Finb/bark-server) is written in Go, and supports Docker and serverless functions.

## Send a Push Notification

### API v2

**Bark is switching to to API v2, which supports webhooks. See [API_V2.md](https://github.com/Finb/bark-server/blob/master/docs/API_V2.md).**

### API v1

The Bark app supports both API v1 and v2, but the UI currently only showcases v1. API v1 supports both HTTP GET or POST requests with the following format.

```
https://{server}/{key}/{body}
https://{server}/{key}/{title}/{body}
```

API v1 also supports optional query strings.

`automaticallyCopy` (boolean)

```
//Automatically copy the body text of a notification (iOS 14.4 and below)
https://api.day.app/key/body?automaticallyCopy=1
```

`badge` (integer)

```
//Specify the badge count on the app icon
https://api.day.app/key/body?badge=3
```

`copy` (string)

```
//Specify clipboard content when copying
https://api.day.app/key/body?copy=1234
```

`group` (string)

```
//Let iOS sort notifications by groups
https://api.day.app/key/body?group=groupName
```

`icon` (string)

```
//Display a custom icon on a notification (iOS 15 and above)
https://api.day.app/key/body?icon=http://day.app/assets/images/avatar.jpg
```

`isArchive` (boolean)

```
//Archive a notification if 1, prevent archiving if 0, default settings will apply if unset
https://api.day.app/key/body?isArchive=1
```

`level` (boolean)

```
//Set importance and delivery timing of a notification
//active (default): presents the notification immediately, lights up the screen, and can play a sound
//timeSensitive: similar to active, but can break through system controls such as Notification Summary and Focus
//passive: adds the notification to the notification list without lighting up the screen or playing a sound
https://api.day.app/key/body?level=timeSensitive
```

`sound` (string)

```
//Select an alert sound for a notification
//Available sounds are located in the 'Sounds' folder and can be previewed in the app
https://api.day.app/key/body?sound=alarm
```

`url` (string)

```
//Open an URL by clicking on a notification
https://api.day.app/key/body?automaticallyCopy=1 
```

## FAQ

* Time Sensitive notifications don’t work.

   Try restarting your device.
* I can’t archive or copy my notifications.

   Try restarting your device. Sometimes Apple’s notification extension ([UNNotificationServiceExtension](https://developer.apple.com/documentation/usernotifications/unnotificationserviceextension)) fails to run. Consequently Bark can’t excute the code to do so. 
* The auto copy function doesn’t work.

   Since iOS 14.5, Apple has tightened clipboard security, and copying is no longer possible without user intervention. You can pull down, long press or open the notification to trigger the auto copy function, or use the system popup button to copy.
* Are there any limits on the number of notifications I can receive?

   There aren’t any limitations. However, if you make a massive amount (> 100,000) of bad requests (e.g., 500 or 404 resulted from bad formatting), your IP will be banned.
* How do I open the Message History tab on startup?

   Bark will open on the same tab it was closed on. Close Bark on the Message History tab.
* Does Bark support POST requests?

   Bark supports GET and POST requests with the same set of parameters. If you want to use webhooks with JSON, you must use API v2. See [API_V2.md](https://github.com/Finb/bark-server/blob/master/docs/API_V2.md).
* My notifications failed to push/got messed up when there are special characters. 

   You need to use URL encoding to convert the special chracters, or the Bark server might not be able to properly interprete the request. Production-level libraries usually handle special characters automatically. 
* How can I make sure my notifications stay private?

   This is how your notification reaches you with Bark:
   Sender → Bark Server → Apple Push Notification Service → Your iPhone → Bark Client
   The Bark server and client are the two attack surfaces that we control. You can mitigate the risks by:
   1. Deploy your own Bark server with [the open-source backend](https://github.com/Finb/bark-server).
   2. Make sure the Bark app has not been tampered.

      Bark uses GitHub Actions to build and publish itself to the App Store. You can verify whether the ‘run_id’ in the app matches the one on GitHub to ensure the app was built from its original codebase.

      You can also find build configurations, version and build numbers in the run log. The version and build numbers must be unique to be accepted by the App Store. Therefore you can verify whether the version and build numbers of your app match the ones in the run log.

## Community Ports

Push from Chrome Extension: [Bark-Chrome-Extension](https://github.com/xlvecle/Bark-Chrome-Extension)

Push from Web with scheduled tasks: [Bark Assisatant](https://api.ihint.me/bark.html)

Push from Windows: [BarkHelper](https://github.com/HsuDan/BarkHelper)

Push from CLI: [bark-cli](https://github.com/JasonkayZK/bark-cli)

Quicker Action: https://getquicker.net/Sharedaction?code=e927d844-d212-4428-758d-08d69de12a3b

Bark for Wox: [Wox.Plugin.Bark](https://github.com/Zeroto521/Wox.Plugin.Bark)

java-bark-server: [https://gitee.com/hotlcc/java-bark-server](https://gitee.com/hotlcc/java-bark-server)
