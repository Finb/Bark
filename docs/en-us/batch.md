
### Individual Users
Batch push is only supported with Json requests, and bark-server needs to be updated to v2.1.9. ([https://api.day.app](https://api.day.app) will not be updated to v2.1.9 for now, and currently does not support batch push.)<br />
Usage:
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

### Middleware Services
If your service requires sending large volumes of push notifications to users in a timely manner, it is recommended to set up your own server. You can provide a Url Scheme to allow users to change the server with one click.

Url Scheme Example:
```
bark://addServer?address=https%3A%2F%2Fapi.day.app
```
bark-server has very low configuration requirements. Below are the QPS test results for various configurations on a US West VPS:

| Cores | Ram | Speed |
| ----- | ----------- |----------- |
| 1 | 3.75 gb |4,023 p/sec |
| 4 | 16 gb |21,413 p/sec |
| 16 | 64 gb |64,516 p/sec |
| 64 | 256 gb |105,263 p/sec |

If QPS does not exceed 200, you can continue to use the public service（[https://api.day.app](https://api.day.app)）。<br />
If QPS exceeds 200, it is recommended to set up your own server. In the future, when the public server is under high load, traffic restrictions may be introduced (currently, there are no restrictions).<br />
If QPS exceeds 3000, it is strongly recommended to set up your own server and add the --max-apns-client-count parameter during deployment. For details, refer to the[Deployment Documentation.](/en-us/deploy)