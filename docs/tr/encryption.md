#### Anlık Bildirim şifreleme nedir?
Anlık bildirim şifreleme, Anlık bildirim içeriğini korumak için bir yöntemdir ve gönderme ve alma sırasında Anlık bildirim içeriğini şifrelemek ve şifresini çözmek için özel bir anahtar kullanır. Bu şekilde, Anlık bildirim içeriği iletim sırasında Bark sunucusu ve Apple APNs sunucusu tarafından elde edilemez veya sızdırılamaz.

#### Özel anahtar ayarlama
1. Uygulama ana sayfasını açın.
2. "Anlık Bildirim Şifreleme"yi bulun, Şifreleme Ayarları'na tıklayın.
3. Şifreleme algoritmasını seçin, ANAHTARI gerektiği gibi doldurun, özel anahtarı kaydetmek için Bitti'ye tıklayın.

#### Şifreli anlık bildirim gönderme
Şifrelenmiş bir anlık bildirim göndermek için önce Bark istek parametrelerini json formatında bir dizeye dönüştürmeniz, ardından dizeyi şifrelemek için önceden ayarlanmış anahtarı ve ilgili algoritmayı kullanmanız ve son olarak şifrelenmiş şifre metnini sunucuya "ciphertext" parametresi olarak göndermeniz gerekir.<br><br>
**Örneğin：**
```sh
#!/usr/bin/env bash

set -e

# bark anahtarı
deviceKey='F5u42Bd3HyW8KxkUqo2gRA'
# anlık bildirim gönderilen veri
json='{"body": "test", "sound": "birdsong"}'

# 16 bit uzunluğunda olmalıdır
key='1234567890123456'
iv='1111111111111111'

# openssl, manuel anahtarların ve IV'lerin ASCII kodlamasını değil, Hex kodlamasını gerektirir.
key=$(printf $key | xxd -ps -c 200)
iv=$(printf $iv | xxd -ps -c 200)

ciphertext=$(echo -n $json | openssl enc -aes-128-cbc -K $key -iv $iv | base64)

# Konsol şunları yazdıracaktır "d3QhjQjP5majvNt5CjsvFWwqqj2gKl96RFj5OO+u6ynTt7lkyigDYNA3abnnCLpr"
echo $ciphertext

curl --data-urlencode "ciphertext=$ciphertext" http://api.day.app/$deviceKey
```
