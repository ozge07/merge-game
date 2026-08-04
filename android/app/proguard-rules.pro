# Flutter ve reklam SDK'sı kendi kurallarını getiriyor; burada yalnızca
# küçültme sırasında kaybolmaması gereken sınıfları koruyoruz.
-keep class io.flutter.** { *; }
-keep class com.google.android.gms.ads.** { *; }

# Flutter motoru "deferred components" (parça parça indirme) desteği için
# Play Core sınıflarına referans veriyor. Bu oyunda o özellik kullanılmıyor ve
# kütüphane bağımlılıklarda yok, o yüzden R8'in eksik sınıf uyarılarını
# susturuyoruz. O kod hiç çalışmıyor.
-dontwarn com.google.android.play.core.**
