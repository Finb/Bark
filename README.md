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
body 推送内容 
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

携带参数 automaticallyCopy=1， 收到推送时，推送内容会自动复制到粘贴板
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

## Chrome 插件
[Bark-Chrome-Extension](https://github.com/xlvecle/Bark-Chrome-Extension)
>这是一款chrome插件能帮你方便地把网页上的文本或者网址推送到Bark手机端。

[Bark-Chrome-Extension 自动复制版](https://github.com/xlvecle/Bark-Chrome-Extension)
>上面插件的修改版，iPhone会自动复制推送内容

效果展示

![](http://wx4.sinaimg.cn/mw690/0060lm7Tly1fyaqyhzdnxg30660dcu0h.gif)


## 在线定时发送
[https://api.ihint.me/bark.html](https://api.ihint.me/bark.html)
