English | **[中文](README.zh.md)**
## Bark
Bark is a push notification tool app. It's free, simple, and secure, leveraging APNs without draining device battery.<br/>
Bark supports many advanced features of iOS notifications, including notification grouping, custom push icons, sounds, time-sensitive notifications, critical alerts, and more.<br/> 
Additionally, Bark supports self-hosted servers and offers encrypted push notifications to ensure privacy and security. <br/>

## Documentation
[https://bark.day.app/#/en-us/](https://bark.day.app/#/en-us/)

## Feedback
[Telegram](https://t.me/joinchat/OsCbLzovUAE0YjY1)

## Usage
1. Open the app and copy the test URL

<img src="https://wx4.sinaimg.cn/mw2000/003rYfqply1grd1meqrvcj60bi08zt9i02.jpg" width=365 />

2. Modify the content and request this URL
```
You can send GET or POST requests, and you'll receive a push notification immediately upon success.

URL structure: The first part is the key, followed by three matches
/:key/:body 
/:key/:title/:body 
/:key/:title/:subtitle/:body 

title: The push title, slightly larger than the body text 
subtitle: The push subtitle
body: The push content, use the newline character '\n' for line breaks 
For POST requests, the parameter names are the same as above
```

## Parameters

* url
```
// Click on the push notification to jump to the specified URL
https://api.day.app/yourkey/url?url=https://www.google.com 
```
* group
```
// Specify the push message group to view pushes by group.
https://api.day.app/yourkey/group?group=groupName
```
* icon (supported on iOS 15 and above)
```
// Specify the push message icon
https://api.day.app/yourkey/icon?icon=http://day.app/assets/images/avatar.jpg
```
* sound
```
// Specify the push message sound
https://api.day.app/yourkey/sound?sound=alarm
```
* call
```
// Play sound repeatedly for 30 seconds
https://api.day.app/yourkey/call?call=1
```
* ciphertext
```
// Encrypted push message
https://api.day.app/yourkey/ciphertext?ciphertext=
```
* Time-sensitive notifications
```
// Set time-sensitive notifications
https://api.day.app/yourkey/时效性通知?level=timeSensitive

// Optional values 
// active: Default value when not set, the system will immediately display the notification by lighting up the screen. 
// timeSensitive: Time-sensitive notification, can be displayed during focus mode. 
// passive: Adds notification to the notification list without lighting up the screen.
```
* Critical alerts
```
// Set critical alerts
https://api.day.app/yourkey/criticalAlert?level=critical

Critical alerts will ignore silent and do not disturb modes, always playing the notification sound and displaying on the screen.
```

## Others
- [Online Scheduled Sending](https://api.ihint.me/bark.html)
- [Windows Push Client](https://github.com/HsuDan/BarkHelper)
- [Cross-platform Command Line Application](https://github.com/JasonkayZK/bark-cli)
- [Bark GitHub Actions](https://github.com/harryzcy/action-bark)
- [Quicker Actions](https://getquicker.net/Sharedaction?code=e927d844-d212-4428-758d-08d69de12a3b)
- [Bark for Wox](https://github.com/Zeroto521/Wox.Plugin.Bark)
- [bark-jssdk](https://github.com/afeiship/bark-jssdk)
- [bark.js](https://github.com/chimpdev/bark.js)
- [java-bark-server](https://gitee.com/hotlcc/java-bark-server)
- [bark-java-sdk](https://github.com/MoshiCoCo/bark-java-sdk)
- [Python for Bark](https://github.com/funny-cat-happy/barknotificator)
- [uTools for Bark](https://u.tools/plugins/detail/PushOne/)
