#### What is push encryption
Push encryption is a method to protect the push content, which uses a custom key to encrypt and decrypt the push content when sending and receiving. In this way, the push content will not be obtained or leaked by Bark server and Apple APNs server during transmission.

#### Set custom key
1. Open APP homepage
2. Find “Push Encryption”, click Encryption Settings 
3. Select encryption algorithm, fill in KEY as required, click Done to save custom key

#### Send encrypted push
To send an encrypted push, you need to first convert the Bark request parameters into a json format string, then use the previously set key and corresponding algorithm to encrypt the string, and finally send the encrypted ciphertext as ciphertext parameter to the server.<br><br>
**For example：**
```sh
#!/usr/bin/env bash

set -e

# bark key
deviceKey='F5u42Bd3HyW8KxkUqo2gRA'
# push payload
json='{"body": "test", "sound": "birdsong"}'

# must be 16 bit long
key='1234567890123456'
iv='1111111111111111'

# openssl requires Hex encoding of manual keys and IVs, not ASCII encoding.
key=$(printf $key | xxd -ps -c 200)
iv=$(printf $iv | xxd -ps -c 200)

ciphertext=$(echo -n $json | openssl enc -aes-128-cbc -K $key -iv $iv | base64)

# The console will print "d3QhjQjP5majvNt5CjsvFWwqqj2gKl96RFj5OO+u6ynTt7lkyigDYNA3abnnCLpr"
echo $ciphertext

curl --data-urlencode "ciphertext=$ciphertext" http://api.day.app/$deviceKey
```
