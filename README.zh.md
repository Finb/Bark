**[English](README.en.md)** | 中文 
## Bark
Bark 是一款免费的推送通知工具 App。<br/>
它简单、安全，基于 APNs 实现，不会额外消耗设备电量。<br/>
<br/>
Bark 支持 iOS 通知的多种高级功能：推送分组、自定义图标和铃声、时效性通知、重要警告等。<br/>
此外，Bark 还支持用户自建服务端，并提供端到端推送加密。APP 是由 Github Action 自动构建和发布，从根本上保障隐私与安全。<br/>

## 下载
<a target='_blank' href='https://apps.apple.com/app/bark-custom-notifications/id1403753865'>
<img src='http://ww2.sinaimg.cn/large/0060lm7Tgw1f1hgrs1ebwj308102q0sp.jpg' width='144' height='49' />
</a>

## 使用文档
[https://bark.day.app](https://bark.day.app)

## 问题反馈
[Bark反馈群](https://t.me/joinchat/OsCbLzovUAE0YjY1)

## 发送推送
1. 打开APP，复制测试URL 

<img src="https://wx4.sinaimg.cn/mw2000/003rYfqply1grd1meqrvcj60bi08zt9i02.jpg" width=365 />

2. 修改内容，请求这个URL
```
可以发 get 或者 post 请求 ，请求成功会立即收到推送 

URL 组成: 第一个部分是 key , 之后有三个匹配 
/:key/:body 
/:key/:title/:body 
/:key/:title/:subtitle/:body 

title 推送标题 比 body 字号粗一点 
subtitle 推送副标题
body 推送内容 换行请使用换行符 '\n'
post 请求 参数名也是上面这些
```

## 功能参数

* url
```
// 点击推送将跳转到url的地址（发送时，URL参数需要编码）
https://api.day.app/yourkey/百度网址?url=https://www.baidu.com 
```
* group
```
// 指定推送消息分组，可在历史记录中按分组查看推送。
https://api.day.app/yourkey/需要分组的推送?group=groupName
```
* icon (仅 iOS15 或以上支持）
```
// 指定推送消息图标
https://api.day.app/yourkey/需要自定义图标的推送?icon=http://day.app/assets/images/avatar.jpg
```
* sound
```
// 指定推送消息的铃声
https://api.day.app/yourkey/sound?sound=alarm
```
* call
```
// 重复播放铃声30s
https://api.day.app/yourkey/call?call=1
```
* ciphertext
```
// 推送加密的密文
https://api.day.app/yourkey/ciphertext?ciphertext=
```
* 时效性通知
```
// 设置时效性通知
https://api.day.app/yourkey/时效性通知?level=timeSensitive

// 可选参数值
// active：不设置时的默认值，系统会立即亮屏显示通知。
// timeSensitive：时效性通知，可在专注状态下显示通知。
// passive：仅将通知添加到通知列表，不会亮屏提醒
```
* 重要警告
```
// 设置时效性通知
https://api.day.app/yourkey/时效性通知?level=critical

重要警告会忽略静音和勿扰模式，始终播放通知声音并在屏幕上显示。
```
## 其他
- [浏览器扩展](https://github.com/ij369/bark-sender)
- [在线定时发送](https://api.ihint.me/bark.html)
- [Windows推送客户端](https://github.com/HsuDan/BarkHelper)
- [跨平台的命令行应用](https://github.com/JasonkayZK/bark-cli)
- [Bark GitHub Actions](https://github.com/harryzcy/action-bark)
- [Quicker 动作](https://getquicker.net/Sharedaction?code=e927d844-d212-4428-758d-08d69de12a3b)
- [Bark for Wox](https://github.com/Zeroto521/Wox.Plugin.Bark)
- [bark-jssdk](https://github.com/afeiship/bark-jssdk)
- [java-bark-server](https://gitee.com/hotlcc/java-bark-server)
- [bark-java-sdk](https://github.com/MoshiCoCo/bark-java-sdk)
- [Python for Bark](https://github.com/funny-cat-happy/barknotificator)
- [uTools for Bark](https://u.tools/plugins/detail/PushOne/)
- [PHP for Bark](https://github.com/guanguans/notify/tree/main/src/Bark/)
