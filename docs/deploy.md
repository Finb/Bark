
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
## 阿里云FC 函数计算
FC 能非常简单的创建**近乎免费**的 bark-server
1. 创建一个[函数](https://fcnext.console.aliyun.com/cn-hangzhou/functions/create), 选择Web函数
2. 从[Release](https://github.com/Finb/bark-server/releases)下载最新的`bark-server_linux_amd64` 到本地
   * 运行`chmod +x ./bark-server_linux_amd64`添加执行权限
   * 压缩文件为zip，后面会用到
4. 填写函数创建相关表单
   * 运行环境选Go 1
   * 代码上传方式选通过ZIP包上传代码
   * 启动命令填 `./bark-server_linux_amd64 -serverless true -addr 0.0.0.0:8080`
   * 端口填 8080
   * 环境变量下添加 Serverless 模式需要的 BARK_KEY 和 BARK_DEVICE_TOKEN 字段。 (填写要求参考 [Serverless](#Serverless)) <br><img src="../_media/environment.png" />
5. 配置函数，优化用量
   * 配置-〉基础配置改为 0.05vCPU 128MB
6. 配置-〉触发器 下可以获取到公网访问地址，在Bark App中添加即可

## 测试
```
curl http://0.0.0.0:8080/ping
```
返回 pong 就证明部署成功了

## 其他

1. APP端负责将<a href="https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622958-application">DeviceToken</a>发送到服务端。 <br>服务端收到一个推送请求后，将发送推送给Apple服务器。然后手机收到推送

2. 服务端代码: <a href='https://github.com/Finb/bark-server'>https://github.com/Finb/bark-server</a><br>

3. App代码: <a href="https://github.com/Finb/Bark">https://github.com/Finb/Bark</a>

