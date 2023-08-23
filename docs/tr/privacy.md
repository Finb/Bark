#### Gizlilik Nasıl Sızdırılır? <!-- {docsify-ignore-all} -->
Bir anlık bildirimin gönderilmesinden alınmasına kadar geçtiği yol şöyledir:<br />
Gönderici<font color='red'> → Sunucu①</font> → Apple APNS sunucusu → Aygıtınız → <font color='red'>Bark Uygulaması②</font>。

Kırmızıyla işaretlenen bu iki yerde gizlilik sızdırma riski olabilir:<br>
* Gönderen HTTPS kullanmıyor veya herkese açık bir sunucu kullanıyor (yazarlar istek günlüklerini görecektir)
* Bark Uygulaması kendisi güvenli değilse, App Store'a yüklenen sürümde değişiklikler yapılmış olabilir.

#### Sunucu Gizlilik Sorununu Nasıl Çözebilirsiniz
* Açık kaynaklı sunucu kodunu kullanarak [kendi sunucunuzu kurarak](/tr/deploy.md) ve HTTPS'yi etkinleştirerek.
* [Şifreli Push Bildirimi](/tr/encryption) kullanarak, içerikleri şifreleyebilirsiniz.

#### Uygulamanın Tamamen Açık Kaynak Kodlarla İnşa Edildiğini Sağlama
Uygulamanın güvenli olmasını ve hiç kimse tarafından (yazar dahil) değiştirilmemesini sağlamak için Bark, GitHub Actions tarafından oluşturulur ve ardından App Store'a yüklenir.<br />
GitHub Çalıştırma Kimliği, Bark uygulama ayarlarında bulunabilir; burada derlemenin geçerli sürümü için kullanılan yapılandırma dosyası, derlemede kullanılan kaynak kodu, App Store'a yüklenen sürümün derleme numarası ve daha fazlası hakkında bilgi bulabilirsiniz.<br>


Aynı derleme numarası App Store'a yalnızca bir kez yüklenebilir, bu nedenle benzersizdir.<br>
Bu numarayı, Mağazadan indirilen Bark Uygulamalarını karşılaştırmak için kullanabilirsiniz ve eşleşirse, App Store'dan indirilen Uygulamanın tamamen açık kaynak kodundan oluşturulduğunu kanıtlar.

Örnek: Bark 1.2.9 - 3<br> 
https://github.com/Finb/Bark/actions/runs/3327969456

1. Derleme sırasındaki commit kimliğini bulun ve derleme sırasında kullanılan kaynak kodlarını görüntüleyin.
2. .github/workflows/testflight.yaml dosyasını inceleyin, tüm işlemleri doğrulayın ve bu işlemlerin kayıtlarının değiştirilmediğinden emin olun.
3. Action Günlüklerini görüntüleyin: https://github.com/Finb/Bark/actions/runs/3327969456/jobs/5503414528
4. Paketlenen Uygulama Kimliği (App ID), Ekip Kimliği (Team ID), App Store'a yüklenen sürüm ve derleme numarası gibi bilgileri bulun.
5. Mağaza için ilgili sürümün IPA dosyasını indirin ve derleme numarasını kayıtlardakiyle karşılaştırın *(Bu numara her uygulama için benzersizdir ve bir kez yüklendikten sonra aynı derleme numarasıyla başka bir sürüm yüklenemez)*.


*Bu kapsamda iOS'un gizlilik açısından incelenmesi dikkate alınmamıştır*