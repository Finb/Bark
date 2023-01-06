
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
## 手动部署

1. 根据平台下载可执行文件:<br> <a href='https://github.com/Finb/bark-server/releases'>https://github.com/Finb/bark-server/releases</a><br>
或自己编译<br>
<a href="https://github.com/Finb/bark-server">https://github.com/Finb/bark-server</a>

2. 运行
```
./bark-server_linux_amd64 -addr 0.0.0.0:8080 -data ./bark-data
```
3. 你可能需要
```
chmod +x bark-server_linux_amd64
```
请注意 bark-server 默认使用 /data 目录保存数据，请确保 bark-server 有权限读写 /data 目录，或者你可以使用 `-data` 选项指定一个目录

## Serverless 
  

  默认提供 Heroku ~~免费~~ 一键部署 (2022-11-28日后收费)<br>
  [![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/finb/bark-server)<br>

  其他支持WEB路由的 serverless 服务器可以使用 `bark-server -serverless true` 开启。

  开启后， bark-server 会读取系统环境变量 BARK_KEY 和 BARK_DEVICE_TOKEN, 需提前设置好。

  | 变量名 | 填写要求 |
  | ---- | ---- |
  | BARK_KEY | 除了不能填 "push" 外，可以随便填写你喜欢的。|
  | BARK_DEVICE_TOKEN | Bark App 设置中显示的 DeviceToken，此 Token 是 APNS 真实设备 Token ,请不要泄露 |

  请注意 Serverless 模式只允许一台设备使用

## 使用
```
curl http://0.0.0.0:8080/ping
```
Ping成功后，在APP端填入你的服务器IP或域名

## 其他

1. APP端负责将<a href="https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622958-application">DeviceToken</a>发送到服务端。 <br>服务端收到一个推送请求后，将发送推送给Apple服务器。然后手机收到推送

2. 服务端代码: <a href='https://github.com/Finb/bark-server'>https://github.com/Finb/bark-server</a><br>

3. App代码: <a href="https://github.com/Finb/Bark">https://github.com/Finb/Bark</a>

