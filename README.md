## 发送推送
1. 打开APP，复制测试URL 

<img src="http://wx3.sinaimg.cn/mw690/0060lm7Tly1g0bu1cv28lj30om0j6gng.jpg" width=365 />

2. 修改内容，请求这个URL
```
可以发 get 或者 post 请求 ，请求成功会立即收到推送 

URL 组成: 第一个部分是 key , 之后有三个匹配 
/:key/:body 
/:key/:title/:body 
/:key/:category/:title/:body 

title 推送标题 比 body 字号粗一点 
body 推送内容 换行请使用换行符 '\n'
category 另外的功能占用的字段，还没开放 忽略就行 
post 请求 参数名也是上面这些
```

## 复制推送内容
收到推送时下拉推送（或在通知中心左滑查看推送）有一个`复制`按钮，点击即可复制推送内容。

> <img src="http://wx4.sinaimg.cn/mw690/0060lm7Tly1g0btjhgimij30ku0a60v1.jpg" width=375 />

```objc
//将复制“验证码是9527”
https://api.day.app/yourkey/验证码是9527
```

携带参数 automaticallyCopy=1， 收到推送时，推送内容会自动复制到粘贴板（如发现不能自动复制，可尝试重启一下手机）
```objc
//自动复制 “验证码是9527” 到粘贴板
https://api.day.app/yourkey/验证码是9527?automaticallyCopy=1 
```


携带copy参数， 则上面两种复制操作，将只复制copy参数的值
```objc
//自动复制 “9527” 到粘贴板
https://api.day.app/yourkey/验证码是9527?automaticallyCopy=1&copy=9527
```

## 其他参数

* url
```
//点击推送将跳转到url的地址（发送时，URL参数需要编码）
https://api.day.app/yourkey/百度网址?url=https://www.baidu.com 
```
* isArchive
```
//指定是否需要保存推送信息到历史记录，1 为保存，其他值为不保存。
//如果不指定这个参数，推送信息将按照APP内设置来决定是否保存。
https://api.day.app/yourkey/需要保存的推送?isArchive=1
```
## 后端代码
[bark-server](https://github.com/Finb/bark-server)
>将后端代码部署在你自己的服务器上。支持Docker

## Chrome 插件
[Bark-Chrome-Extension](https://github.com/xlvecle/Bark-Chrome-Extension)
>这是一款chrome插件能帮你方便地把网页上的文本或者网址推送到Bark手机端。

效果展示

![](http://wx4.sinaimg.cn/mw690/0060lm7Tly1fyaqyhzdnxg30660dcu0h.gif)


## 在线定时发送
[https://api.ihint.me/bark.html](https://api.ihint.me/bark.html)

## Windows推送客户端
[https://github.com/HsuDan/BarkHelper](https://github.com/HsuDan/BarkHelper)

## 跨平台的命令行应用
[https://github.com/JasonkayZK/bark-cli](https://github.com/JasonkayZK/bark-cli)

## Quicker 动作
使用 Quicker 软件在 Windows 上将选中文字一键推送到iPhone，支持打开URL和自动复制推送内容
[https://getquicker.net/Sharedaction?code=e927d844-d212-4428-758d-08d69de12a3b](https://getquicker.net/Sharedaction?code=e927d844-d212-4428-758d-08d69de12a3b)

## Bark for Wox
[https://github.com/Zeroto521/Wox.Plugin.Bark](https://github.com/Zeroto521/Wox.Plugin.Bark)
