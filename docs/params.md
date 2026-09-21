## 请求参数
以下参数在 GET、POST 表单、JSON 请求体中名字完全一样，按需组合使用，使用方式参考[使用教程](/tutorial)。

### 参数目录
- 内容
  - [title](#title) 推送标题
  - [subtitle](#subtitle) 推送副标题
  - [body](#body) 推送内容
  - [markdown](#markdown) Markdown 内容
- 设备
  - [device_key](#device_key) 设备 key
  - [device_keys](#device_keys) 批量推送
- 展示与分组
  - [group](#group) 消息分组
  - [icon](#icon) 推送图标
  - [image](#image) 推送图片
  - [badge](#badge) 推送角标
- 提醒与铃声
  - [level](#level) 推送级别
  - [volume](#volume) 重要警告音量
  - [call](#call) 重复响铃
  - [sound](#sound) 自定义铃声
- 复制与跳转
  - [copy](#copy) 指定复制内容
  - [url](#url) 点击跳转地址
  - [action](#action) 点击操作弹窗
- 加密
  - [ciphertext](#ciphertext) 加密推送
  - [iv](#iv) 加密初始向量
- 保存与管理
  - [isArchive](#isarchive) 是否保存
  - [ttl](#ttl) 保存有效期
  - [id](#id) 通知唯一标识
  - [delete](#delete) 删除通知

### 内容
#### title
推送标题，显示在通知卡片的第一行。<br>
不传时通知只显示正文；

#### subtitle
推送副标题，显示在标题下方、正文上方的较小字号位置，适合放来源、状态之类的补充信息。<br>
不传则不显示这一行；

#### body
推送正文，通知卡片上的主要内容。

#### markdown
推送正文，支持基础 Markdown 格式，传了这个参数会忽略 body。<br>
支持加粗、斜体、删除线、链接、行内代码、代码块、1-6 级标题、引用、有序/无序列表、任务列表；图片在通知里会降级成链接文本。<br>
发送时请注意处理内容中的特殊字符。

### 设备
#### device_key
推送目标设备的 key，作用和 URL 路径里的 key 一样。<br>
JSON 请求且路径为 `/push` 时，用它把 key 放进请求体，用法参考[使用教程](/tutorial)。<br>
这个参数由服务器使用，App 本身不读取。

#### device_keys
key 数组，一次推送给多台设备，仅支持 JSON 请求，示例见[批量推送](/batch)。<br>
公共服务器一次最多 10 个设备，自建服务器无上限；需要 bark-server v2.1.9 及以上版本。

### 展示与分组
#### group
对消息分组，同一个 `group` 的推送在系统通知中心和历史记录里会归到一组，如图所示。<br>
<img src="../_media/group-notification-center.jpg" width=428 /><br>
在 App 的历史消息列表里可以点击切换按钮，选择分组查看消息。<br>
<img src="../_media/group-history.jpg" width=428 /><br>
也可以在收到推送时，长按或下拉系统推送横幅，选择对某个分组静音，静音期间该分组的推送不会亮屏提醒。

#### icon
自定义通知图标，填图片 URL，设置后会替换通知里默认的 Bark 图标。<br>
图标会自动缓存在本机，同一个 URL 只会下载一次，之后即使图片地址不可用也能正常显示；首次下载超过 10 秒会退回默认图标。<br>
需要 iOS 15 及以上。<br>
<img src="../_media/icon-example.jpg" width=428 />

#### image
推送图片的 URL，收到推送后展开通知即可看到大图，App 历史记录里也会显示。<br>
图片同样会缓存在本机，下载超过 10 秒时这条推送不带图片显示。

#### badge
App 图标上的角标数字，直接设置成传入的值，不会在原有数字上累加。<br>
传 `0` 会清除角标，同时清掉通知中心里该 App 的通知。

### 提醒与铃声
#### level
推送的级别，可选值：<br>
- `active`：默认值，系统会立即亮屏显示通知
- `timeSensitive`：时效性通知，专注模式下也能显示
- `passive`：仅将通知添加到通知列表，不会亮屏提醒
- `critical`：重要警告，静音模式下也会响铃，样式如下图

`critical` 需要在 App 里授权「重要警告」，没有授权时会降级成普通通知，推送铃声音量由 [volume](#volume) 控制。<br>
需要 iOS 15 及以上。<br>
<img src="../_media/critical-alert.jpg" width=428 />

#### volume
重要警告（`level=critical`）的通知音量，取值范围 0-10，不传默认值为 5。<br>
只在重要警告时生效，普通推送的音量由系统控制，不受这个参数影响。

#### call
传 `"1"` 时把通知铃声循环播放 30 秒（默认只响一次），用于需要强提醒的场景。<br>
配合 [sound](#sound) 指定铃声；和 `level=critical` 一起用时可以用 [volume](#volume) 调整音量。

#### sound
推送使用的铃声名称，例如 `minuet`。<br>
App 内置铃声和自己导入的铃声都可以用，导入的铃声需要是 `.caf` 格式、时长不超过 30 秒，导入方法见 App 内的铃声设置。<br>
不传时使用 App 设置里的默认铃声；名称不存在时系统会回退到默认提示音。

### 复制与跳转
#### copy
指定复制推送时复制的内容，比如只复制正文里的验证码。<br>
不传这个参数时，复制到的是推送正文；

#### url
点击推送时跳转的 URL，支持 URL Scheme 和 Universal Link。<br>
`http` / `https` 链接会优先用 Universal Link 打开，失败时用 Safari 打开，其他 Scheme 直接交给系统处理。

#### action
传 `alert` 时，点击推送打开 App 会弹出操作弹窗，可以复制推送内容或分享出去。<br>
传 `none` 时点击推送只打开 App，不跳转到具体页面；其他值按默认行为处理。<br>
同时传了 [url](#url) 时优先按 `url` 跳转。

### 加密
#### ciphertext
加密推送的密文，推送内容对 Bark 服务器和苹果 APNs 都不可见，只有本机 App 能解密。<br>
密文里可以放 `title`、`subtitle`、`body`、`sound`、`group`、`badge` 等参数，具体加密方法见[推送加密](/encryption)。<br>
解密失败时通知内容会显示 `Decryption Failed`。

#### iv
供加密推送使用。<br>
加密时使用的随机 IV 值，需要将其一并传给服务器；

### 保存与管理
#### isArchive
是否把这条推送保存到 App 的历史记录。传 `1` 保存，传其他值不保存。<br>
不传时按 App 内的设置决定是否保存，默认为保存。

#### ttl
已保存推送的有效期，单位为秒，只对保存到历史记录的消息生效。<br>
到期后 App 会自动删除这条历史记录，同时移除通知中心里对应的推送；<br>
适合只在一段时间内有意义的消息，比如验证码、临时告警。

#### id
通知的唯一标识。使用相同的 `id` 时，新的推送会更新替换原来那条通知，不会重复堆在通知中心里，适合做进度、状态类通知。<br>
需要 Bark v1.5.2、bark-server v2.2.5 及以上版本；JSON 传参必须使用字符串类型，传数字不生效。<br>
删除通知（[delete](#delete)）也需要靠它来定位。

#### delete
传 `"1"` 时删除指定通知，会同时从系统通知中心和 App 历史记录里删掉，需要搭配 [id](#id) 使用。<br>
这条指令通过静默推送下发，需要在系统设置里为 Bark 打开「后台App刷新」，否则无效。
