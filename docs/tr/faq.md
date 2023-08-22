#### Anlık bildirim kullanım limiti <!-- {docsify-ignore-all} -->
Normal isteklerin (HTTP durum kodu 200) sınırı yoktur.<br>
Ancak 5 dakika içinde 1000'den fazla hata isteği (HTTP durum kodu 400 404 500) yapılırsa, <b>IP 24 saat boyunca YASAKLANACAKTIR.</b> 

#### Zamana duyarlı bildirimler çalışmıyor
Sorunu çözmek için <b>cihazınızı yeniden başlatmayı</b> deneyebilirsiniz.

#### Bildirim geçmişi kaydedilemiyor veya kopyala düğmesine tıklamadan kilit ekranında aşağı iterek veya sola kaydırarak kopyalanamıyor
Sorunu çözmek için <b>cihazınızı yeniden başlatmayı</b> deneyebilirsiniz.<br />
Bazı nedenlerden dolayı, anlık bildirim hizmeti uzantısı ([UNNotificationServiceExtension](https://developer.apple.com/documentation/usernotifications/unnotificationserviceextension)) düzgün bir şekilde çalıştırılamadı ve bildirimleri kaydetme kodu düzgün bir şekilde yürütülmedi.

#### Otomatik kopyalama anlık bildirim hatası
iOS 14.5 sürümünden sonra, izinlerin sıkılaştırılması nedeniyle, push bildirimi alırken içeriği otomatik olarak panoya kopyalamak mümkün değildir. <br/>
Geçici olarak push bildirimini aşağı çekebilir veya ekran kilidinde sola kaydırarak görüntüleyip otomatik olarak kopyalayabilirsiniz, veya açılır penceredeki kopyala düğmesine tıklayabilirsiniz.

#### Bildirim geçmişi sayfasını varsayılan olarak aç
Uygulamayı tekrar açtığınızda, son açılan sayfaya atlayacaktır.<br />
Eğer geçmiş mesaj sayfasındaysanız, uygulamadan çıkın. Uygulamayı tekrar açtığınızda yine geçmiş mesaj sayfasında olacaksınız.

#### Anlık Bildirim API POST isteğini destekliyor mu?
Bark GET POST'u destekler, Json kullanımını destekler.<br>
Hangi istek yöntemi olursa olsun, parametre adları aynıdır. Bakınız [kullanım öğreticisi](tr/tutorial)

#### Özel karakterler anlık bildirim işleminde başarısızlığa neden oluyor. Örneğin: İtme içeriği bağlantı içeriyor veya + gibi özel karakterler boşluğa dönüşüyor. 
Bunun nedeni düzensiz bağlantı sorunudur. Sıklıkla olur<br>
URL eklerken, URL kodlama parametrelerine dikkat edin

```sh
# Örneğin
https://api.day.app/key/{push content}

# Eğer {anlık bildirim içeriği} ise
"a/b/c/"

# O zaman URLnin son durumu şöyledir
https://api.day.app/key/a/b/c/
# İlgili rota bulunamaz ve arka uç programı 404 döndürür

#Eklemeden önce {anlık bildirim içeriği} öğesini url kodlamalısınız
https://api.day.app/key/a%2Fb%2Fc%2F
```
 Gelişmiş bir HTTP kütüphanesi kullanırsanız, parametreler otomatik olarak işlenecek ve manuel kodlamaya ihtiyaç duymayacaksınız. <br>
Ancak URL'yi kendiniz eklerseniz, parametrelerdeki özel karakterler için özel dikkat göstermeniz gerekir. **Özel karakterlerin varlığını dikkate almadan ve otomatik olarak URL kodlama katmanı uygulamak genellikle daha iyi bir yaklaşımdır.**

#### Gizlilik ve güvenlik nasıl sağlanır?
Bakınız [gizlilik güvenlik](/tr/privacy)
