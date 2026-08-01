#### 什么是推送加密
推送加密是一种保护推送内容的方法，它使用自定义秘钥在发送和接收时对推送内容进行加密和解密。<br>这样，推送内容在传输过程中就不会被 Bark 服务器和苹果 APNs 服务器获取或泄露。

#### 设置自定义秘钥
1. 打开APP首页
2. 找到 “推送加密” ，点击加密设置
3. 选择加密算法和模式，按要求填写 KEY。ECB 和 CBC 存在已知的安全问题，仅为兼容旧配置保留；新配置请选择 GCM
4. IV 建议留空，由发送方在每次推送时随机生成并通过 iv 参数发送；固定 IV 一旦复用会导致 nonce 重复，直接削弱甚至破坏加密的安全性，只有需要兼容已经写死固定 IV 的旧脚本时才手动填写
5. 点击完成保存自定义秘钥

#### 发送加密推送
要发送加密推送，首先需要把 Bark 请求参数转换成 json 格式的字符串，然后用之前设置的秘钥和相应的算法对字符串进行加密，最后把加密后的密文作为ciphertext参数发送到服务器。<br>
IV 应当每次随机生成并通过 iv 参数随请求发送，复用固定 IV 会导致 nonce 重复、削弱甚至破坏加密的安全性；请求不带 iv 参数时会退回使用加密设置里保存的固定 IV，仅用于兼容旧脚本。<br><br>
**GCM 模式示例（推荐）：**
```js
const crypto = require('crypto');

// bark key
const deviceKey = 'F5u42Bd3HyW8KxkUqo2gRA';
// push payload
const json = JSON.stringify({ body: "test", sound: "birdsong" });

// 必须16位
const key = '1234567890123456';
// IV可以是随机生成的，但如果是随机的就需要放在 iv 参数里传递。
const iv = crypto.randomBytes(6).toString('hex');

// AES-128-GCM
const cipher = crypto.createCipheriv('aes-128-gcm', Buffer.from(key, 'utf8'), Buffer.from(iv, 'utf8'));
const encrypted = Buffer.concat([
  cipher.update(json, 'utf8'),
  cipher.final()
]);
const tag = cipher.getAuthTag()

const combined = Buffer.concat([encrypted, tag])
const ciphertext = combined.toString('base64')

// 密文可能有特殊字符，所以记得 URL 编码一下。
const pushUrl = `https://api.day.app/${deviceKey}?ciphertext=${encodeURIComponent(ciphertext)}&iv=${encodeURIComponent(iv)}`;
```

**CBC 示例（仅用于兼容旧配置）：**
```sh
#!/usr/bin/env bash

set -e

# bark key
deviceKey='F5u42Bd3HyW8KxkUqo2gRA'
# push payload
json='{"body": "test", "sound": "birdsong"}'

# 必须16位
key='1234567890123456'
# IV可以是随机生成的，但如果是随机的就需要放在 iv 参数里传递。
iv=$(openssl rand -hex 8)

# OpenSSL 要求输入的 Key 和 IV 需使用十六进制编码。
key=$(printf $key | xxd -ps -c 200)
ivHex=$(printf $iv | xxd -ps -c 200)

# 如果提示 Decryption Failed， 尝试在 base64 命令后面 加上 -w 0
ciphertext=$(echo -n $json | openssl enc -aes-128-cbc -K $key -iv $ivHex | base64)

echo $ciphertext

# 密文可能有特殊字符，所以记得 URL 编码一下。
curl --data-urlencode "ciphertext=$ciphertext" --data-urlencode "iv=$iv" https://api.day.app/$deviceKey
```

在 App 加密设置页点击“复制示例”，可以直接复制包含你自己 Key 和设备地址的脚本。