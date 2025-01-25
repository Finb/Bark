
### 个人用户
批量推送仅支持Json请求，需 bark-server 更新至 v2.1.9。（[https://api.day.app](https://api.day.app) 暂时不会更新至 v2.1.9, 目前还不支持批量推送）<br />
用法:
```sh
curl -X "POST" "https://api.day.app/push" \
     -H 'Content-Type: application/json; charset=utf-8' \
     -d $'{
  "title": "Title",
  "body": "Body",
  "sound": "minuet",
  "group": "test",
  "device_keys": ["key1", "key2", ... ]
}'
```

### 中间服务
如果你的服务需要大批量且及时地向用户发送推送，建议自建服务端。可以提供 Url Scheme 方便用户一键更改服务器。

Url Scheme 示例：
```
bark://addServer?address=https%3A%2F%2Fapi.day.app
```
bark-server 对配置要求很低，以下是美西 VPS 各配置下的 QPS 测试结果 ：

| Cores | Ram | Speed |
| ----- | ----------- |----------- |
| 1 | 3.75 gb |4,023 p/sec |
| 4 | 16 gb |21,413 p/sec |
| 16 | 64 gb |64,516 p/sec |
| 64 | 256 gb |105,263 p/sec |

若 QPS 不高于 200，可继续使用公共服务（[https://api.day.app](https://api.day.app)）。<br />
若 QPS 超过 200，推荐自建服务端，未来在公共服务器负载过高时，可能会引入流量限制（目前尚未限制）。<br />
若 QPS 超过 3000，尽量自建服务端，部署时添加 `--max-apns-client-count` 参数，详情请查看[部署文档](/deploy)