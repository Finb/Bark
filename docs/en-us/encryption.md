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

# Key
# Can be a 16-byte raw string (length 16) or a Hex string (length 32)
key='1234567890123456'

# IV
# Method A: Randomly generate a 16-byte IV (Recommended) -> Output 32-char Hex string
iv=$(openssl rand -hex 16)

# Method B: Manually specify a 16-byte raw string (Legacy compatibility)
# iv='1234567890123456'

# Process Key and IV
# If key/iv is a raw string, convert to Hex using xxd. If it is already a Hex string, use directly.
# Demonstrating raw string conversion for Key:
key=$(printf $key | xxd -ps -c 200)

# If Key is Hex (e.g. 32 chars), use directly: 
# key='...' (no xxd)

# IV is already a Hex string (Method A), no xxd conversion needed.
# If using Method B (raw string), you need: iv=$(printf $iv | xxd -ps -c 200)

ciphertext=$(echo -n $json | openssl enc -aes-128-cbc -K $key -iv $iv | base64)

# The console will print the ciphertext
echo $ciphertext

curl --data-urlencode "ciphertext=$ciphertext" http://api.day.app/$deviceKey
```
