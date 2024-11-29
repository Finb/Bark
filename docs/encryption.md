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

# Must be 16 bit long
key='1234567890123456'
# IV can be randomly generated, but if it is random, it needs to be passed in the iv parameter.
iv='1234567890123456'

# openssl requires Hex encoding of manual keys and IVs, not ASCII encoding.
key=$(printf $key | xxd -ps -c 200)
iv=$(printf $iv | xxd -ps -c 200)

ciphertext=$(echo -n $json | openssl enc -aes-128-cbc -K $key -iv $iv | base64)

# The console will print "+aPt5cwN9GbTLLSFri60l3h1X00u/9j1FENfWiTxhNHVLGU+XoJ15JJG5W/d/yf0"
echo $ciphertext

# URL encoding the ciphertext, there may be special characters.
curl --data-urlencode "ciphertext=$ciphertext" --data-urlencode "iv=1234567890123456" https://api.day.app/$deviceKey
```