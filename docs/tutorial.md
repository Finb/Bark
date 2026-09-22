## 发送推送
1. 打开APP，复制测试命令 
<img src="../_media/example.jpg" width=428 />

2. 按自身需求修改示例，执行命令后手机将收到推送
3. 发送请求可以选择自己喜欢的方式，Bark 并不做限制

## URL格式
推送 URL 由推送 key、参数 title、参数 subtitle、参数 body 组成，有下面三种方式

```
/:key/:body 
/:key/:title/:body 
/:key/:title/:subtitle/:body 
```

POST 还可使用下面的路径，然后将所有参数放进请求体中：
```
/push
```

## 请求方式
##### GET 请求参数拼接在 URL 后面，例如：
```sh
curl https://api.day.app/your_key/推送内容?group=分组&copy=复制
```
*手动拼接参数到URL上时，请注意URL编码问题，可以参考阅读[常见问题：URL编码](/faq?id=%e6%8e%a8%e9%80%81%e7%89%b9%e6%ae%8a%e5%ad%97%e7%ac%a6%e5%af%bc%e8%87%b4%e6%8e%a8%e9%80%81%e5%a4%b1%e8%b4%a5%ef%bc%8c%e6%af%94%e5%a6%82-%e6%8e%a8%e9%80%81%e5%86%85%e5%ae%b9%e5%8c%85%e5%90%ab%e9%93%be%e6%8e%a5%ef%bc%8c%e6%88%96%e6%8e%a8%e9%80%81%e5%bc%82%e5%b8%b8-%e6%af%94%e5%a6%82-%e5%8f%98%e6%88%90%e7%a9%ba%e6%a0%bc)*

##### POST 请求参数放在请求体中，例如：
```sh
curl -X POST https://api.day.app/your_key \
     -d'body=推送内容&group=分组&copy=复制'
```
##### POST 请求支持JSON，例如：
```sh
curl -X "POST" "https://api.day.app/your_key" \
     -H 'Content-Type: application/json; charset=utf-8' \
     -d $'{
  "body": "Test Body",
  "title": "Test Title",
  "badge": 1,
  "sound": "minuet",
  "icon": "https://day.app/assets/images/avatar.jpg",
  "group": "test",
  "url": "https://bark.day.app"
}'
```

##### key 可以放进请求体中，URL 路径须为 /push，例如：
```sh
curl -X "POST" "https://api.day.app/push" \
     -H 'Content-Type: application/json; charset=utf-8' \
     -d '{
  "body": "Test Body",
  "title": "Test Title",
  "device_key": "your_key"
}'
```

#### MCP
VS Code:  
```js
{
  "servers": {
    "bark": {
      "type": "http",
      "url": "https://api.day.app/mcp/{key}"
    }
  }
}
```

Claude Code:   
```sh
claude mcp add bark --transport http https://api.day.app/mcp/{key}
```  
或者  
```js
{
  "mcpServers": {
    "bark": {
      "type": "http",
      "url": "https://api.day.app/mcp/{key}"
    }
  }
}
```  
> 注意将 url 中的 key 替换成你自己的


## 请求参数
所有支持的参数，详细说明见[请求参数](/params)。

## Bark 支持的应用程序和插件
* [SmsForwarder](https://github.com/pppscn/SmsForwarder) 监控 Android 手机短信、来电、APP通知，并根据指定规则转发到Bark。
* [acme.sh](https://github.com/acmesh-official/acme.sh/wiki/notify#16-set-notification-for-ios-bark) 从 ZeroSSL，Let's Encrypt 等 CA 生成免费的证书。可以使用 Bark 接收 acme.sh cronjob 任务通知。
* [Uptime-Kuma](https://github.com/louislam/uptime-kuma) 自托管监控工具, 支持Bark作为告警通道。
* [Apprise](https://github.com/caronc/apprise) 可以给几乎所有平台发送通知，支持Bark。
* [浏览器扩展](https://github.com/ij369/bark-sender) 将网页内容发送到手机
* [RevenueBell](https://github.com/woxiqingxian/RevenueBell) 独立开发者工具，将苹果订阅、续订、购买等收入事件，通过 Bark 推送到你的手机。

## 快捷指令
Bark 支持使用快捷指令直接发送推送
