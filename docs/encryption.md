#### 什么是推送加密
推送加密是一种保护推送内容的方法，它使用自定义秘钥在发送和接收时对推送内容进行加密和解密。<br>这样，推送内容在传输过程中就不会被 Bark 服务器和苹果 APNs 服务器获取或泄露。

#### 设置自定义秘钥
1. 打开APP首页
2. 找到 “推送加密” ，点击加密设置
3. 选择加密算法，按要求填写KEY，点击完成保存自定义秘钥

#### 发送加密推送
要发送加密推送，首先需要把 Bark 请求参数转换成 json 格式的字符串，然后用之前设置的秘钥和相应的算法对字符串进行加密，最后把加密后的密文作为ciphertext参数发送到服务器。<br><br>
**示例：**
```sh
#!/usr/bin/env bash

set -e

# bark key
deviceKey='F5u42Bd3HyW8KxkUqo2gRA'
# push payload
json='{"body": "test", "sound": "birdsong"}'

# 密钥 (Key)
# 可以是 16 字节的普通字符串 (长度16)，也可以是 Hex 编码字符串 (长度32)
key='1234567890123456'

# 初始向量 (IV)
# 方式 A：随机生成 16 字节 IV (推荐) -> 输出 32 字符的 Hex 字符串
iv=$(openssl rand -hex 16)

# 方式 B：手动指定 16 字节字符串 (兼容旧版)
# iv='1234567890123456'

# 处理 Key 和 IV
# 如果 key/iv 是普通字符串，需要转成 Hex。如果是 Hex 字符串，则直接使用。
# 这里演示 key 是普通字符串的情况：
key=$(printf $key | xxd -ps -c 200)
# 如果 Key 是 Hex (例如 32 字符)，则直接使用: 
# key='...' (无需 xxd)

# iv 已经是 Hex 字符串 (方式 A)，无需 xxd 转换。
# 如果使用方式 B (普通字符串)，则需要：iv=$(printf $iv | xxd -ps -c 200)

ciphertext=$(echo -n $json | openssl enc -aes-128-cbc -K $key -iv $iv | base64)

# The console will print the ciphertext
echo $ciphertext

# URL encoding the ciphertext, there may be special characters.
curl --data-urlencode "ciphertext=$ciphertext" --data-urlencode "iv=1234567890123456" https://api.day.app/$deviceKey
```