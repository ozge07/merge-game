import 'package:flutter_test/flutter_test.dart';
import 'package:merge_game/i18n/app_language.dart';
import 'package:merge_game/i18n/strings.dart';

/// Yüksek seviye birleşmelerinde çıkan tebrik mesajları.
void main() {
  const tr = Strings(AppLanguage.tr);
  const en = Strings(AppLanguage.en);

  group('birleşme tebriği', () {
    test('düşük seviyelerde tebrik yok', () {
      // İlk seviyeler sık sık birleşiyor; her seferinde kutlama yorucu olurdu.
      for (var level = 1; level <= 4; level++) {
        expect(
          tr.mergePraise(level),
          isNull,
          reason: 'seviye $level için tebrik olmamalı',
        );
      }
    });

    test('beşinci seviyeden itibaren tebrik veriliyor', () {
      for (var level = 5; level <= 11; level++) {
        expect(
          tr.mergePraise(level),
          isNotNull,
          reason: 'seviye $level tebrik almalı',
        );
        expect(en.mergePraise(level), isNotNull);
      }
    });

    test('seviye yükseldikçe mesaj değişiyor', () {
      final mesajlar = <String>{
        for (var level = 5; level <= 10; level++) tr.mergePraise(level)!,
      };
      // Her seviye kendi mesajını almalı; hepsi aynı olsaydı ilerleme
      // hissi kaybolurdu.
      expect(mesajlar.length, 6);
    });

    test('en üst seviyelerin hepsi aynı mesajı paylaşıyor', () {
      expect(tr.mergePraise(11), tr.mergePraise(12));
    });

    test('İngilizce sürümde Türkçe karakter yok', () {
      final turkce = RegExp('[çğıöşüÇĞİÖŞÜ]');
      for (var level = 5; level <= 11; level++) {
        expect(turkce.hasMatch(en.mergePraise(level)!), isFalse);
      }
      expect(turkce.hasMatch(en.chainPraise(3)), isFalse);
    });
  });

  group('zincir tebriği', () {
    test('zincir sayısını içeriyor', () {
      expect(tr.chainPraise(3), contains('3'));
      expect(en.chainPraise(4), contains('4'));
    });
  });
}
