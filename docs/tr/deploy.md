
## Docker 
```
docker run -dt --name bark -p 8080:8080 -v `pwd`/bark-data:/data finab/bark-server
```

## Docker-Compose 
```
mkdir bark && cd bark
curl -sL https://git.io/JvSRl > docker-compose.yaml
docker-compose up -d
```
## Manuel Dağıtım

1. Platforma göre çalıştırılabilir dosyayı indirin.<br> <a href='https://github.com/Finb/bark-server/releases'>https://github.com/Finb/bark-server/releases</a><br>
veya kendiniz derleyin<br>
<a href="https://github.com/Finb/bark-server">https://github.com/Finb/bark-server</a>

2. Çalıştırın
```
./bark-server_linux_amd64 -addr 0.0.0.0:8080 -data ./bark-data
```
3. Gerekebilir
```
chmod +x bark-server_linux_amd64
```
Lütfen unutmayın ki bark-server varsayılan olarak verileri saklamak için /data dizinini kullanır. Bark-server'ın /data dizinine okuma ve yazma izinlerine sahip olduğundan emin olun veya farklı bir dizini belirtmek için `-data` seçeneğini kullanabilirsiniz.

## Sunucusuz Mimari (Serverless) 
  

  Heroku ücretsiz dağıtım sunar (2022-11-28 tarihine kadar).<br>
  [![Dağıtım](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/finb/bark-server)<br>

  Web yönlendirmelerini destekleyen diğer serverless sunucuları, Serverless modunu etkinleştirmek için `bark-server -serverless true` komutunu kullanabilirsiniz.

  Etkinleştirildiğinde, bark-server sistem ortam değişkenleri BARK_KEY ve BARK_DEVICE_TOKEN'ı okuyacaktır. Bu değerleri önceden ayarlamanız gerekmektedir.

  | Değişken Adı | Gereksinimler |
  | ---- | ---- |
  | BARK_KEY | "push" dışında herhangi bir değer girilebilir. |
  | BARK_DEVICE_TOKEN | Bark App ayarlarında görünen DeviceToken. Bu Token gerçek APNS cihaz tokenidir, lütfen sızdırmayın. |

  Lütfen Serverless modunun yalnızca bir cihaza izin verdiğini unutmayın.

## Render
Render, ücretsiz bir bark-server oluşturmayı çok kolay hale getirir.
1. [Render](https://dashboard.render.com/register/) hesabı oluşturun.
2. [Yeni Web Hizmeti](https://dashboard.render.com/select-repo?type=web) oluşturun.
3. Aşağıdaki URL'yi **Public Git repository** giriş kutusuna girin
```
https://github.com/Finb/bark-server
```
4. **Devam et**'i tıklayın ve formu doldurun
   * **Name** - Ad, herhangi bir ad seçin, örneğin bark-server.
   * **Region** - Sunucu bölgesi, size en yakın olanı seçin.
   * **Start Command** - Programı çalıştırma komutu, `./app -serverless true` şeklinde doldurun. (Lütfen ./app öncesindeki noktayı unutmayın)
   * **Instance Type** - *Free*'yi seçin, ücretsiz olan yeterlidir.
   * Seçenekleri genişletmek için **Advanced**'e tıklayın.
   * **Add Environment Variable**'a tıklayarak Serverless modu için gereken BARK_KEY ve BARK_DEVICE_TOKEN alanlarını ekleyin. (Gereksinimler için [Serverless](#Serverless) bölümüne bakın) <br><img src="_media/environment.png" />
   * Diğer seçenekler değiştirilmez
5. Sayfanın alt kısmında **Create Web Service** düğmesine tıklayın ve durumun **In progress**'ten **Live**'a geçmesini bekleyin, bu birkaç dakika ila on dakika sürebilir.
6. Sayfanın üst kısmında sunucu URL'nizi bulun, bu bark-server sunucu URL'si, Bark App'e ekleyebilirsiniz
```
https://[sizin-sunucu-adiniz].onrender.com
```
7. Sunucu ekleme başarısız olursa bir süre bekleyebilir ve tekrar deneyebilirsiniz. Servis henüz hazır olmayabilir.
8. Bark App'e ekleme yapmanıza gerek yoktur, doğrudan çağrı yaparak anlık bildirim gönderebilirsiniz. BARK_KEY yukarıda doldurduğunuz anahtardır.
```
https://[sizin-sunucu-adiniz].onrender.com/BARK_KEY/推送内容
```

## Test
```
curl http://0.0.0.0:8080/ping
```
Eğer **pong** dönerse, dağıtım başarılı demektir.

## Diğer

1. Uygulama tarafı sunucu tarafına <a href="https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622958-application">DeviceToken</a>göndermekten sorumludur.<br>Sunucu tarafı bir push isteği aldığında, Apple sunucusuna bir anlık bildirim gönderir. Ardından cep telefonu anlık bildirimi alır.

2. Sunucu kodu:<a href='https://github.com/Finb/bark-server'>https://github.com/Finb/bark-server</a><br>

3. Uygulama Kodu: <a href="https://github.com/Finb/Bark">https://github.com/Finb/Bark</a>

