#### What is push encryption
Push encryption is a method to protect the push content, which uses a custom key to encrypt and decrypt the push content when sending and receiving. In this way, the push content will not be obtained or leaked by Bark server and Apple APNs server during transmission.

#### Set custom key
1. Open APP homepage
2. Find “Push Encryption”, click Encryption Settings 
3. Select the encryption algorithm and mode, and fill in KEY as required. ECB and CBC have known security issues and are only kept for backward compatibility with older configurations — choose GCM for a new setup
4. Leave IV blank so the sender generates a random IV for every push and sends it in the iv parameter; reusing a fixed IV causes nonce reuse, which weakens or breaks the encryption's security guarantees. Only fill in a fixed IV if you need to stay compatible with an existing script that already hardcodes one
5. Click Done to save the custom key

#### Send encrypted push
To send an encrypted push, you need to first convert the Bark request parameters into a json format string, then use the previously set key and corresponding algorithm to encrypt the string, and finally send the encrypted ciphertext as ciphertext parameter to the server.<br>
The IV should be randomly generated for every push and sent in the iv parameter — reusing a fixed IV causes nonce reuse and weakens or breaks the encryption; if the request has no iv parameter, the IV saved in the encryption settings is used as a fallback for compatibility with older scripts.<br><br>
**GCM example (recommended)：**
```js
const crypto = require('crypto');

// bark key
const deviceKey = 'F5u42Bd3HyW8KxkUqo2gRA';
// push payload
const json = JSON.stringify({ body: "test", sound: "birdsong" });

// Must be 16 bit long
const key = '1234567890123456';
// IV can be randomly generated, but if it is random, it needs to be passed in the iv parameter.
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

// URL encoding the ciphertext, there may be special characters.
const pushUrl = `https://api.day.app/${deviceKey}?ciphertext=${encodeURIComponent(ciphertext)}&iv=${encodeURIComponent(iv)}`;
```

**CBC example (for compatibility with older configurations)：**
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
iv=$(openssl rand -hex 8)

# openssl requires Hex encoding of manual keys and IVs, not ASCII encoding.
key=$(printf $key | xxd -ps -c 200)
ivHex=$(printf $iv | xxd -ps -c 200)

# If you get a 'Decryption Failed' prompt, try adding '-w 0' after the base64 command.
ciphertext=$(echo -n $json | openssl enc -aes-128-cbc -K $key -iv $ivHex | base64)

echo $ciphertext

# URL encoding the ciphertext, there may be special characters.
curl --data-urlencode "ciphertext=$ciphertext" --data-urlencode "iv=$iv" https://api.day.app/$deviceKey
```

Tap “Copy Example” on the Encryption Settings page in the app to copy a script that already has your own key and server address filled in.
