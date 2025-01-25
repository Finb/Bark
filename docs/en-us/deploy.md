
## Docker 
```
docker run -dt --name bark -p 8080:8080 -v `pwd`/bark-data:/data finab/bark-server
```

## Docker-Compose 
```
mkdir bark && cd bark
curl -sL https://git.io/JvSRl > docker-compose.yaml
docker-compose up -d
```
## Manual Deployment

1. Download the executable file based on your platform:<br> <a href='https://github.com/Finb/bark-server/releases'>https://github.com/Finb/bark-server/releases</a><br>
Or compile it yourself:<br>
<a href="https://github.com/Finb/bark-server">https://github.com/Finb/bark-server</a>

2. Run the server:
```
./bark-server_linux_amd64 -addr 0.0.0.0:8080 -data ./bark-data
```
3. You may need to make the file executable:
```
chmod +x bark-server_linux_amd64
```
Note: The bark-server uses the /data directory by default to store data. Ensure it has read/write permissions or specify a custom directory with the -data option.


## Cloudflare Worker
[https://github.com/cwxiaos/bark-worker](https://github.com/cwxiaos/bark-worker)

## Test
```
curl http://0.0.0.0:8080/ping
```
If it returns pong, the deployment is successful.

## High-Volume Push Notifications (For regular users, ignore this. Use only if QPS exceeds 3000)
If you need to send a large volume of push notifications in a short period, you can configure the bark-server to use multiple APNS Clients for delivery.
Each Client represents a new connection (which may connect to different APNs servers). Please set this parameter according to the number of CPU cores. The number of Clients cannot exceed the number of CPU cores (if exceeded, it will automatically be set to the current number of CPU cores).

#### Docker
```
docker run -dt --name bark -p 8080:8080 -v `pwd`/bark-data:/data finab/bark-server bark-server --max-apns-client-count 4
```

#### Docker-Compose 
```yaml
version: '3.8'
services:
  bark-server:
    image: finab/bark-server
    container_name: bark-server
    restart: always
    volumes:
      - ./data:/data
    ports:
      - "8080:8080"
    command: bark-server --max-apns-client-count 4
```

#### Manual Deployment
```
./bark-server --addr 0.0.0.0:8080 --data ./bark-data --max-apns-client-count 4
```


## 其他

1. The app sends the <a href="https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622958-application">DeviceToken</a>to the server.<br>The server sends push requests to Apple’s servers.
2. Server code: <a href='https://github.com/Finb/bark-server'>https://github.com/Finb/bark-server</a><br>
3. App code: <a href="https://github.com/Finb/Bark">https://github.com/Finb/Bark</a>

