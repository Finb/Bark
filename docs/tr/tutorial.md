## Anlık Bildirim Gönderimi
1. Uygulamayı açın, test URL'sini kopyalayın.

<img src="_media/example.jpg" width=365 />

2. İçeriği değiştirin ve URL'ye istek atın.<br>
GET veya POST isteği gönderebilirsiniz, istek başarılıysa hemen bir push alacaksınız.

## URL Formatı
URL, bir anlık bildirim anahtarı, "title" parametresi ve "body" parametresinden oluşur. İki farklı kombinasyon şekli vardır:

```
/:key/:body 
/:key/:title/:body 
```

## İstek Yöntemi
##### GET isteği parametreleri URL'nin sonuna eklenir, örneğin:
```sh
curl https://api.day.app/your_key/BildirimIcerigi?group=Grup&copy=KopyalanacakIcerik
```
*Elle parametreleri URL'ye eklerken URL kodlama sorunlarına dikkat etmelisiniz, [Sıkça Sorulan Sorular: URL Kodlama](tr/faq?id=%C3%96zel-karakterler-anl%C4%B1k-bildirim-i%C5%9Fleminde-ba%C5%9Far%C4%B1s%C4%B1zl%C4%B1%C4%9Fa-neden-oluyor-%C3%96rne%C4%9Fin-%C4%B0tme-i%C3%A7eri%C4%9Fi-ba%C4%9Flant%C4%B1-i%C3%A7eriyor-veya-gibi-%C3%B6zel-karakterler-bo%C5%9Flu%C4%9Fa-d%C3%B6n%C3%BC%C5%9F%C3%BCyor)*

##### POST isteği parametreleri istek gövdesine yerleştirilir, örneğin:
```sh
curl -X POST https://api.day.app/your_key \
     -d'body=Push İçeriği&group=Grup&copy=Kopyala'
```
##### POST isteği JSON'ı destekler, örneğin:
```sh
curl -X "POST" "https://api.day.app/your_key" \
     -H 'Content-Type: application/json; charset=utf-8' \
     -d $'{
  "body": "Test Bark Server",
  "title": "Test Başlık",
  "badge": 1,
  "sound": "minuet.caf",
  "icon": "https://day.app/assets/images/avatar.jpg",
  "group": "test",
  "url": "https://mritd.com"
}'
```

##### JSON isteği anahtarı istek gövdesine yerleştirilebilir, URL yolu */push* olmalıdır, örneğin
```sh
curl -X "POST" "https://api.day.app/push" \
     -H 'Content-Type: application/json; charset=utf-8' \
     -d $'{
  "body": "Test Bark Server",
  "title": "Test Başlık",
  "device_key": "sizin_anahtarınız"
}'
```

## İstek Parametreleri
Desteklenen parametrelerin listesi, belirli bir etkiyi uygulamada nasıl görüneceğini görmek için uygulama içinden önizleme yapabilirsiniz.

| Parametre | Açıklama |
| ----- | ----------- |
| title | Anlık bildirim başlığı |
| body | Anlık bildirim içeriği |
| level | Anlık bildirim kesme seviyesi. <br>**active:** Varsayılan değer, sistem bildirimi hemen göstermek için ekranı aydınlatacaktır.<br>**timeSensitive:** Zamana duyarlı bildirim, odaklanmış durumda bildirim gösterebilir.<br>**passive:** Bildirimi yalnızca bildirim listesine ekler, hatırlatmak için ekranı aydınlatmaz. |
| badge | Anlık bildirim rozeti, herhangi bir sayı olabilir. |
| autoCopy | iOS 14.5'ten önce otomatik olarak anlık bildirim içeriğini kopyalar, iOS 14.5'ten sonraysa manuel olarak uzun basmalı veya anlık bildirim aşağı çekilmelidir |
| copy | Bir anlık bildirim kopyalanırken, kopyalanacak içeriği belirtin; bu parametre belirtilmezse tüm anlık bildirim içeriğini kopyalar. |
| sound | Anlık bildirim için bir ses seçebilirsiniz. |
| icon | Anlık bildirim için özel bir simge ayarlayın ve ayarlanan simge varsayılan Bark simgesinin yerini alacaktır. Simgeler otomatik olarak yerel olarak önbelleğe alınır ve aynı simge URL'si yalnızca bir kez indirilir. |
| group | Bildirimleri gruplandırın, anlık bildirimler gruplanmış bir şekilde bildirim merkezinde görüntülenir.<br>Ayrıca geçmiş mesajlar listesinde farklı grupları görüntülemeyi de seçebilirsiniz. |
| isArchive | 1 ile gönderirseniz, anlık bildirim kaydedilir; diğer bir değer gönderirseniz kaydedilmez. Göndermezseniz, kaydetme ayarlarına göre karar verilir. |
| url | Anlık bildirime tıklanınca gidilecek URL, URL Şeması ve Evrensel Bağlantıları destekler. |