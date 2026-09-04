# Merge Game — çalışma kuralları

## Kod standardı

Kod her zaman **sade, okunabilir ve profesyonel** olmalı.

**Fonksiyonlar tek bir iş yapar.** Bir fonksiyonun adını yazarken "ve"
kullanmak zorunda kalıyorsan, o fonksiyon ikiye ayrılmalı.

**Gereksiz karmaşıklıktan kaçınılır.** İhtiyaç duyulmayan soyutlama
yazılmaz: tek uygulaması olan arayüz, tek kullanımlık yardımcı sınıf, ileride
gerekebilecek parametre. Basit çözüm işi görüyorsa basit çözüm doğrudur.
Bunun tersi de kural: aynı şey üç yerde tekrar ediyorsa ortaklaştırılır.

**İsimlendirme açıklayıcı olur.** Değişkenin adı ne tuttuğunu, fonksiyonun
adı ne yaptığını söyler. `x`, `tmp`, `data`, `handle` gibi adlar kabul
edilmez. Kısaltma yapılmaz; `hesaplananHamleSayisi`, `hhs`'den iyidir.

**Kritik kararlara kısa bir gerekçe eklenir.** Kodun *ne yaptığını* anlatan
yorum gereksizdir — kod zaten onu söylüyor. Yorum, birinin "bu neden böyle?"
diye soracağı yere yazılır: alışılmadık bir tercih, bir hatanın düzeltmesi,
ölçüme dayanan bir karar. Ölçüm varsa **sayı yazılır**:

```dart
/// Renk merdiveni bilerek doygun ve sıcaktan soğuğa gidiyor: oyuncu iki objeyi
/// yan yana koyduğunda aynı seviyede olup olmadığını renkten anlayabilmeli.
/// Renk körlüğü olanlar için ayrıca her seviyenin kenar sayısı farklı.
```

"Performans için" ya da "daha iyi çalışıyor" gerekçe değildir.

## Bu depoya özgü kurallar

**Yorumlar ve belgeler Türkçe.** Kullanıcıya görünen metinler asla koda
gömülmez; `lib/i18n/strings.dart` içindeki `Strings` üzerinden `_pick(tr, en)`
ile iki dilde geçer. Yeni metin eklerken iki dil birlikte yazılır — çeviri
paketi ve kod üretimi bilerek kullanılmıyor, iki dil yan yana dursun diye.

**Oyunun adı kodda `merge_game`, ekranda `SIDE GROW`.** Paket adı
(`com.bluelabsgames.mergegame`), depo adı (`merge-game`) ve mağaza adı
birbirini tutmuyor; hiçbiri diğerine uydurulmaya çalışılmaz — üçü de yayında.

**Yayındaki kullanıcının verisi bozulmaz.** Yarım oyun `board.toJson()` ile
saklanıyor — yani **kayıt biçimi depoda olmayan bir dosyada tanımlı**
(`lib/game/merge_board.dart`). `GameSaveStore` gelen haritayı yorumlamıyor,
olduğu gibi yazıp okuyor; şemayı değiştiren tek yer tahta. Alan adı ya da
anlamı değişecekse eski kaydın nasıl okunacağı yazılır, yoksa yayındaki
oyuncular "devam et" dedikleri anda bozuk tahtaya düşer.

Kalıcı anahtarlar — adları değişirse oyuncunun verisi sıfırlanır:
`merge_saved_game`, `merge_high_score`, `app_language`.

**Sürükleme yalnızca komşu hücreye.** Bu bir kısıt değil, oyunun
kaybedilebilmesinin şartı: serbest bırakılsaydı dolu tahtada hep birleştirilecek
bir çift bulunurdu ve "hamle kalmadı" hiç oluşmazdı (25 hücre, 11 seviye).
Gerekçesi `NOTES.md`'de.

**Seviye rengi tek başına anlam taşımaz.** Her seviyenin kenar sayısı da
farklı (`lib/game/level_style.dart`); renk körlüğü olan oyuncu için tek ayırt
edici bu. Yeni seviye eklenirse ikisi birden tanımlanır.

**Hata yutuluyorsa gerekçesi yazılır.** Ses açılamadığında oyun sessiz devam
eder, kayıt okunamadığında sıfırdan başlar — ama hata `AppLog.warn` ile
loglanır. `debugPrint` doğrudan çağrılmaz, tek log noktası `lib/app_log.dart`.
Sessizce yutulan hata kabul edilmez.

**Düz `flutter build` ile yayın paketi üretilmez.** Unity Ads kimliği
`--dart-define` ile geçilmezse reklamlar sessizce kapanır (`AdConfig.adsEnabled`
hem `kReleaseMode` hem kimlik ister). Gerçek reklam için `tool/build_release.sh`,
test reklamı için `tool/build_qa.sh`. Yayın dışı derlemelerde reklam sağlayıcısı
hiç kurulmuyor; bu bilinçli bir karar, AdMob hesabı geçersiz trafikten
kapandığı için (bkz. `lib/game/ad_config.dart`).

**Testler davranışı korur, kodu tekrar etmez.** Bir hata düzeltildiyse testi,
düzeltme geri alındığında düşmelidir. Yazdığın testin bunu yaptığını
doğrula.

**Çekirdek dosyalar depoda değil.** `lib/game/merge_board.dart`,
`test/merge_board_test.dart` ve `NOTES.md` bilerek `.gitignore`'da; bu depo bir
vitrin. Tahta, hamle ve birleşme kurallarının ayrıntısı `NOTES.md`'de yazılı.
**Bu dosyaların bu diskten başka kopyası yok** — yedek bundle'larda da
bulunmuyorlar (hiç commit edilmediler). Değiştirdiysen elle yedeklenmeleri
gerekir. Açık depoya commit'lemek geri alınamaz: dosya git geçmişinde kalır,
`.gitignore`'a geri koymak gizlemez.

## Ajanlar

Roller kullanıcı seviyesinde tanımlı (`~/.claude/agents/`), yani bütün
projelerde geçerli:

| Ajan | Ne zaman |
| --- | --- |
| `frontend-agent` | Ekran, bileşen, stil, animasyon, durum yönetimi |
| `backend-agent` | Veri katmanı, kalıcı depolama, iş mantığı, dış servisler |
| `business-analyst-agent` | Özellik öncesi gereksinim netleştirme, kod sonrası gözden geçirme (kod yazmaz) |

Sıralı kullanım işe yarar: önce analist gereksinimi netleştirir, sonra
geliştirici yazar, sonra analist gözden geçirir.

**Bu projede backend yok.** Oyun tamamen çevrimdışı; ağa yalnızca reklam
SDK'sı çıkıyor. `backend-agent`'ın buradaki karşılığı `lib/game/` altındaki
`*_store.dart` dosyaları ve `lib/i18n/app_language.dart`'taki `LanguageStore`.
