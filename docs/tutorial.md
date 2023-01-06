## 发送推送
1. 打开APP，复制测试URL 

<img src="https://wx4.sinaimg.cn/mw2000/003rYfqply1grd1meqrvcj60bi08zt9i02.jpg" width=365 />

2. 修改内容，请求这个URL。<br>
可以发 get 或者 post 请求 ，请求成功会立即收到推送 

## URL格式
URL由 推送key、参数 title、参数 body 组成。有下面两种组合方式

```
/:key/:body 
/:key/:title/:body 
```

## 请求方式
GET 请求参数拼接在 URL 后面，例如：
```sh
curl https://api.day.app/your_key/推送内容?group=分组&copy=复制
```
POST 请求参数放在请求体中，例如：
```sh
curl -X POST https://api.day.app/your_key \
     -d'body=推送内容&group=分组&copy=复制'
```
POST 请求支持JSON，例如：
```sh
curl -X "POST" "https://api.day.app/your_key" \
     -H 'Content-Type: application/json; charset=utf-8' \
     -d $'{
  "body": "Test Bark Server",
  "title": "bleem",
  "badge": 1,
  "category": "myNotificationCategory",
  "sound": "minuet.caf",
  "icon": "https://day.app/assets/images/avatar.jpg",
  "group": "test",
  "url": "https://mritd.com"
}'
```
## 请求参数
支持的参数列表，具体效果可在APP内预览。

| 参数 | 说明 |
| ----- | ----------- |
| title | 推送标题 |
| body | 推送内容 |
| level | 推送中断级别。 <br>active：默认值，系统会立即亮屏显示通知<br>timeSensitive：时效性通知，可在专注状态下显示通知。<br>passive：仅将通知添加到通知列表，不会亮屏提醒。 |
| badge | 推送角标，可以是任意数字 |
| autoCopy | iOS14.5以下自动复制推送内容，iOS14.5以上需手动长按推送或下拉推送 |
| copy | 复制推送时，指定复制的内容，不传此参数将复制整个推送内容。 |
| sound | 可以为推送设置不同的铃声 |
| icon | 为推送设置自定义图标，设置的图标将替换默认Bark图标。<br>图标会自动缓存在本机，相同的图标 URL 仅下载一次。 |
| group | 对消息进行分组，推送将按group分组显示在通知中心中。<br>也可在历史消息列表中选择查看不同的群组。 |
| isArchive | 传 1 保存推送，传其他的不保存推送，不传按APP内设置来决定是否保存。 |
| url | 点击推送时，跳转的URL ，支持URL Scheme 和 Universal Link |