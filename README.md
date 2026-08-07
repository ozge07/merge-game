# Merge Game

Flutter + Flame ile yapılmış birleştirme oyunu. 5x5 tahtada aynı seviyeden
objeleri birleştirip daha yükseğine çıkıyorsun.

## Nasıl oynanır

- **Boş bir kareye dokun** → sıradaki obje oraya gelir. Ne geleceğini üstteki
  kutuda görürsün.
- **Aynı seviyeden iki obje yan yana gelirse** birleşip bir üst seviyeye
  çıkar. Çapraz komşuluk saymaz.
- **Bir objeyi sürükleyip komşu kareye taşıyabilirsin**; aynı seviyedekileri
  böyle buluşturuyorsun.
- Birleşme yeni bir komşuluk doğurursa zincir kendiliğinden devam eder ve
  puan katlanır.
- **Tahta dolar ve birleşecek komşu kalmazsa oyun biter.**

## Ekranlar

- **Menü** — Devam Et (yalnızca kayıtlı oyun varsa), Yeni Oyun, Nasıl Oynanır,
  Çıkış. Rekor menüde rozet olarak duruyor.
- **Oyun** — üstte puan, en yüksek seviye, sıradaki obje ve rekor; sağ üstte
  bilgi ve menü düğmeleri.
- **Oyun sonu** — "OYUN BİTTİ / hamle kalmadı", puan, ulaşılan seviye, rekor
  kutlaması; reklam izleyip devam etme, tekrar oyna, menü.

## Yardımcı davranışlar

- **Nasıl oynanır** balonu bilgi düğmesinden açılıyor, bir süre sonra
  kendiliğinden kapanıyor, tekrar açılabiliyor.
- **Boşta ipucu:** bir süre hamle yapılmazsa önerilen hamlenin kareleri yanıp
  sönüyor. Sarı halka "bunu şuraya sürükle", mavi halka "buraya dokun" demek.
- **Kayıt:** her hamleden sonra tahta cihaza yazılıyor; menüdeki Devam Et
  kaldığın yerden açıyor. Oyun bitince kayıt siliniyor.
- **Reklamla devam:** hamle kalmayınca ödüllü reklam izleyip tahtada yer
  açabiliyorsun, tur başına bir kez.

## Görsel

Hiç asset yok, her şey kodla çiziliyor. Seviye arttıkça hem renk hem kenar
sayısı değişiyor (üçgen → kare → beşgen → … → daire), böylece renk körlüğü
olan oyuncular da seviyeleri ayırt edebiliyor. Uygulama ikonu da aynı şekilde
kodla üretiliyor.

## Depoda olanlar

| Dosya | Sorumluluk |
|---|---|
| `lib/main.dart` | Uygulama girişi, paylaşılan servislerin kurulumu |
| `lib/ui/menu_screen.dart` | Ana menü, rekor rozeti, hareketli arka plan |
| `lib/ui/game_page.dart` | `GameWidget` ve katmanların bağlanması |
| `lib/ui/hud_overlay.dart` | Puan, en yüksek seviye, sıradaki obje, düğmeler |
| `lib/ui/game_over_overlay.dart` | Oyun sonu kartı, reklamla devam |
| `lib/ui/how_to_play.dart` | Nasıl oynanır balonu ve bilgi düğmesi |
| `lib/game/merge_game.dart` | Flame tarafı: kamera, hücre koordinatı, dokunuş ve sürükleme |
| `lib/game/tile_component.dart` | Tek bir objenin çizimi |
| `lib/game/level_style.dart` | Seviye başına renk ve şekil |
| `lib/game/game_save_store.dart` | Yarım kalan oyunun kaydı |
| `lib/game/high_score_store.dart` | Rekorun saklanması |
| `lib/game/ads_controller.dart` | Ödüllü reklam yükleme ve gösterme |
| `lib/game/ad_config.dart` | Test/gerçek reklam kimliği seçimi |
| `tool/gen_icon.py` | Uygulama ikonunu kodla üreten betik |

## Depoda olmayanlar

Aşağıdaki dosyalar `.gitignore` ile hariç tutuldu:

- `lib/game/merge_board.dart` — birleşme, zincir, puanlama, ipucu bulma ve
  oyun sonu kuralları
- `test/merge_board_test.dart` — yukarıdaki kuralların testleri

Bu yüzden `flutter run` ve `flutter test` bu depo tek başına klonlandığında
çalışmaz. Depo arayüzü, proje yapısını ve iskeleti gösteriyor.

## Reklamlar

Oyun sonunda ödüllü reklam izleyen oyuncu tahtada yer açıp devam edebiliyor.
Tur başına bir kez.

**Geliştirirken reklam tamamen kapalı.** Yayın (release) dışı hiçbir
derlemede reklam SDK'sı başlatılmıyor, ağa tek bir istek bile gitmiyor, test
reklamı dahi açılmıyor. Kod düzeyinde kilit: üç ayrı noktada `kReleaseMode`
kontrolü var ve `test/ads_controller_test.dart` bunları koruyor.

Sebep somut: daha önce kullanılan AdMob hesabı geçersiz trafik nedeniyle
kapatıldı. İkinci bir reddedilmeyi imkânsız kılmanın tek kesin yolu,
geliştirme derlemesinin reklam ağıyla hiç konuşmaması.

Sağlayıcı bağlı değilken ödül **doğrudan veriliyor**; özellik geliştirirken
de çalışıyor.

Reklam ağı Unity Ads. Oyun hangi ağın kullanıldığını bilmiyor — yalnızca
`RewardedAdProvider` arayüzünü çağırıyor. Kimlik kaynak koda yazılmıyor,
yayın derlemesinde `--dart-define` ile geçiliyor (`tool/build_release.sh`,
`.gitignore`'da).

## Yayın hazırlığı

- **İkon:** `python3 tool/gen_icon.py` — hiç dış kütüphane yok, PNG `zlib` ve
  `struct` ile elle yazılıyor. Beş yoğunluk, uyarlanabilir ikonun ön katmanı
  ve mağaza için 512x512.
- **Açılış ekranı:** oyunun koyu zemin rengi; varsayılan beyaz parlama yok.
- **İmza:** `android/key.properties` içindeki keystore ile. Dosya yoksa
  release debug anahtarlarına düşüyor (o paket Play'e yüklenemez).
- **Küçültme:** release'te R8 açık.

Yayın paketi:

```bash
./tool/build_release.sh          # app bundle
./tool/build_release.sh apk      # apk
```

`store/DATA_SAFETY.md` Play Console'daki Data Safety formunun cevaplarını,
`PRIVACY_POLICY.md` gizlilik politikasını içeriyor.

### Depoya girmeyen gizli dosyalar

`android/key.properties` ve `tool/build_release.sh`
gerçek kimlik ve anahtar taşıdığı için `.gitignore`'da.
