#### 隐私如何泄露 <!-- {docsify-ignore-all} -->
一条推送从发送到接收经过路线是：<br>
发送端 <font color='red'> →服务端①</font> → 苹果APNS服务器 → 你的设备 → <font color='red'>Bark APP②</font>。

红色的两处地方可能泄露隐私 <br>
* 发送端未使用HTTPS或使用公共服务器*（作者会看到请求日志）*
* Bark App 本身不安全，上传到 App Store 的版本经过修改。

#### 解决服务端隐私问题
* 你可以使用开源的后端代码，自行[部署后端服务](/deploy.md)，开启HTTPS。
* 使用自定义秘钥的[加密推送](/encryption) ，加密推送内容

#### 保证 APP 完全由开源代码构建
为确保 App 是安全、未经任何人（包含作者）修改过的，Bark 是由 GitHub Actions 构建后上传到 App Store。<br>
Bark应用设置内可以查看到 GitHub Run Id，点击可在里面找到当前版本构建所使用的配置文件、编译时的源代码、上传到 App Store 的版本 build 号 等等信息。<br>


同一个版本 build 号仅能上传到 App Store 一次，所以这个号是唯一的。<br>
可用此号对比从商店下载的 Bark App，如果一致则证明从 App Store 下载的 App 是完全由开源代码构建。

举例： Bark 1.2.9 - 3 <br> 
https://github.com/Finb/Bark/actions/runs/3327969456

1. 找到编译时的 commit id ，可以查看编译时完整的源码
2. 查看 .github/workflows/testflight.yaml ，验证所有 Action ，确保 Action 打印的日志未被篡改
3. 查看 Action Logs https://github.com/Finb/Bark/actions/runs/3327969456/jobs/5503414528
4. 找到 打包的App ID、Team ID、上传到 App Store 的版本与 build 号等信息。
5. 下载商店对应版本ipa，比对版本build号是否与日志中一致*（这个号码同一个APP是唯一的，成功上传了就不能再以相同的版本build号上传）*


*这里不考虑iOS是否泄露隐私*