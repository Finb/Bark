
## Docker 
```
docker run -dt --name bark -p 8080:8080 -v `pwd`/bark-data:/data finab/bark-server
```
> 镜像也可使用 ghcr.io/finb/bark-server

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


## Cloudflare Worker
[https://github.com/cwxiaos/bark-worker](https://github.com/cwxiaos/bark-worker)
> bark-worker 仅推荐个人用户使用，适合发送少量推送，不适合频繁或大批量推送。


## 宝塔面板

1. 登录宝塔面板，在菜单栏中点击 `Docker`

2. 首次会提示安装`Docker`和`Docker Compose`服务，点击立即安装，若已安装请忽略。

3. 安装完成后在左上角搜索框中搜索`Bark`，点击`安装`。

4. 设置域名等基本信息，点击`确定`
- 名称：应用名称，默认`bark_随机字符`
- 版本选择：默认`latest`
- 域名：如需通过域名直接访问，请在此配置域名并将域名解析到服务器
- 允许外部访问：如您需通过`IP+Port`直接访问，请勾选，如您已经设置了域名，请不要勾选此处
- 端口：默认`8080`，可自行修改

5. 提交后面板会自动进行应用初始化，大概需要`1-3`分钟，初始化完成后即可使用。

## 测试
```
curl http://0.0.0.0:8080/ping
```
返回 pong 就证明部署成功了

## 大批量推送（普通用户忽略，QPS超过 3000 再使用）
如果你需要短时间大批量推送，可以配置 bark-server 使用多个 APNS Clients 推送，
每一个 Client 代表一个新的连接（可能连接到不同的APNs服务器），请根据 CPU 核心数设置这个参数，Client 数量不能超过CPU核心数（超过会自动设置为当前 CPU 核心数）。

配置方法：
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

#### 手动部署
```
./bark-server --addr 0.0.0.0:8080 --data ./bark-data --max-apns-client-count 4
```


## 其他

1. APP端负责将<a href="https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622958-application">DeviceToken</a>发送到服务端。 <br>服务端收到一个推送请求后，将发送推送给Apple服务器。然后手机收到推送

2. 服务端代码: <a href='https://github.com/Finb/bark-server'>https://github.com/Finb/bark-server</a><br>

3. App代码: <a href="https://github.com/Finb/Bark">https://github.com/Finb/Bark</a>

