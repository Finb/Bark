### APNS Arayüzünü Doğrudan Kullanma
Eğer cihazınızın DeviceToken'ı varsa (Uygulama içinde bulunabilir), doğrudan Apple APNS arayüzünü çağırarak cihaza anlık bildirim gönderebilirsiniz. Ayrıca, Uygulamaya sunucu eklemeye gerek yoktur.<br>
Aşağıda komut satırında anlık bildirim gönderme örneği verilmiştir:

```shell
# Çevresel değişkenleri ayarla
# Key'i indir https://raw.githubusercontent.com/Finb/bark-server/master/deploy/AuthKey_LH4T9V5U4R_5U8LBRXG3A.p8 
# Key dosyasının yolunu aşağıya gir
TOKEN_KEY_FILE_NAME= 
# Uygulama ayarlarından kopyalanan DeviceToken'ı buraya yapıştır
DEVICE_TOKEN=

# Aşağıdakileri değiştirmeyin !!!
TEAM_ID=5U8LBRXG3A
AUTH_KEY_ID=LH4T9V5U4R
TOPIC=me.fin.bark
APNS_HOST_NAME=api.push.apple.com

# TOKEN oluştur
JWT_ISSUE_TIME=$(date +%s)
JWT_HEADER=$(printf '{ "alg": "ES256", "kid": "%s" }' "${AUTH_KEY_ID}" | openssl base64 -e -A | tr -- '+/' '-_' | tr -d =)
JWT_CLAIMS=$(printf '{ "iss": "%s", "iat": %d }' "${TEAM_ID}" "${JWT_ISSUE_TIME}" | openssl base64 -e -A | tr -- '+/' '-_' | tr -d =)
JWT_HEADER_CLAIMS="${JWT_HEADER}.${JWT_CLAIMS}"
JWT_SIGNED_HEADER_CLAIMS=$(printf "${JWT_HEADER_CLAIMS}" | openssl dgst -binary -sha256 -sign "${TOKEN_KEY_FILE_NAME}" | openssl base64 -e -A | tr -- '+/' '-_' | tr -d =)
# Eğer koşullar elverişliyse, en iyi performans için bu betiği geliştirerek TOKEN'ı önbelleğe almanız iyi olur. 
# Aynı TOKEN'i 30 dakika içinde tekrar kullanmak, her 30 dakikada bir yeniden oluşturmaktan daha iyidir.
# Apple dokümantasyonu, TOKEN'ın en erken 20 dakika arayla yeniden oluşturulabileceğini belirtmektedir. TOKEN'ın maksimum geçerlilik süresi 60 dakikadır.
# Ancak, sık sık yeniden oluşturmak TOKEN'ın başarısız olmasına neden olabilir.
# Bu bilgiyi paylaşmak istiyoruz, belki sık sık TOKEN oluşturmak nedeniyle anlık bildirim gönderiminde sorun yaşanabilir.
AUTHENTICATION_TOKEN="${JWT_HEADER}.${JWT_CLAIMS}.${JWT_SIGNED_HEADER_CLAIMS}"

# Anlık bildirim gönderme
curl -v --header "apns-topic: $TOPIC" --header "apns-push-type: alert" --header "authorization: bearer $AUTHENTICATION_TOKEN" --data '{"aps":{"alert":"test"}}' --http2 https://${APNS_HOST_NAME}/3/device/${DEVICE_TOKEN}

```

### Push Parametre Formatı
Bknz. https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/generating_a_remote_notification<br>
"mutable-content" : 1 getirdiğinizden emin olun, aksi takdirde anlık bildirim uzantısı çalışmayacak ve anlık bildirimi kaydetmeyecektir.

Örnek：
```js
{
    "aps": {
        "mutable-content": 1,
        "alert": {
            "title" : "Başlık",
            "body": "İçerik"
        },
        "category": "myNotificationCategory",
        "sound": "minuet.caf"
    },
    "icon": "https://day.app/assets/images/avatar.jpg"
}
```