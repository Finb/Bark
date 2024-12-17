
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


## Cloudflare Worker
[https://github.com/cwxiaos/bark-worker](https://github.com/cwxiaos/bark-worker)


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

## Render
Render 能非常简单的创建免费的 bark-server
1. [注册](https://dashboard.render.com/register/)一个 Render 账号
2. 创建一个 [New Web Service](https://dashboard.render.com/select-repo?type=web)
3. 在底部的 **Public Git repository** 输入框输入下面的URL
```
https://github.com/Finb/bark-server
```
4. 点击 **Continue** 输入表单
   * Name - 名称，随便取个名字，例如 bark-server
   * Region - 服务器地区，选择离你近的
   * Start Command - 程序执行命令,填`./app -serverless true`。（注意不要漏了 ./app 前面的点）
   * Instance Type - 选 Free ，免费的足够用了。
   * 点击 Advanced 展开更多选项
   * 点击 Add Environment Variable 添加 Serverless 模式需要的 BARK_KEY 和 BARK_DEVICE_TOKEN 字段。 (填写要求参考 [Serverless](#Serverless)) <br><img src="../_media/environment.png" />
   * 其他的默认不动
5. 点击底部的 Create Web Service 按钮，然后等待状态从 In progress 变成 Live，可能需要几分钟到十几分钟。
6. 页面顶部找到你的服务器URL，这个就是bark-server服务器URL，在 Bark App 中添加即可
```
https://[your-server-name].onrender.com
```
7. 如果添加失败，可以等待一段时间再试，有可能服务还没准备好。
8. 不添加到 Bark App 中也可以，直接调用就能发推送。BARK_KEY 就是上面环境变量中你填写的。
```
https://[your-server-name].onrender.com/BARK_KEY/推送内容
```

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

