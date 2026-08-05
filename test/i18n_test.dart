import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:merge_game/i18n/app_language.dart';
import 'package:merge_game/i18n/strings.dart';

/// Dil desteğinin bütünlüğü: İngilizce seçiliyken ekranda Türkçe metin
/// kalmamalı. Metni `Strings`'e yazıp arayüze bağlamayı unutmak kolay.
void main() {
  group('çeviri bütünlüğü', () {
    test('İngilizcede Türkçe karakter kalmıyor', () {
      const en = Strings(AppLanguage.en);
      final turkce = RegExp('[çğıöşüÇĞİÖŞÜ]');

      final metinler = <String, String>{
        'continueGame': en.continueGame,
        'newGame': en.newGame,
        'howToPlay': en.howToPlay,
        'exit': en.exit,
        'playFirstGame': en.playFirstGame,
        'record': en.record(120),
        'pressBackAgain': en.pressBackAgain,
        'score': en.score,
        'highest': en.highest,
        'nextUp': en.nextUp,
        'recordSmall': en.recordSmall(90),
        'backToMenu': en.backToMenu,
        'gameOver': en.gameOver,
        'noMovesLeft': en.noMovesLeft,
        'points': en.points,
        'highestLevel': en.highestLevel,
        'newRecord': en.newRecord,
        'watchingAd': en.watchingAd,
        'continueSubtitle': en.continueSubtitle,
        'playAgain': en.playAgain,
        'menu': en.menu,
        'howToTitle': en.howToTitle,
        'gotIt': en.gotIt,
        'ruleTap': en.ruleTap,
        'ruleMerge': en.ruleMerge,
        'ruleDrag': en.ruleDrag,
        'ruleChain': en.ruleChain,
        'ruleGameOver': en.ruleGameOver,
      };

      for (final girdi in metinler.entries) {
        expect(
          turkce.hasMatch(girdi.value),
          isFalse,
          reason: '${girdi.key} çevrilmemiş: "${girdi.value}"',
        );
      }
    });

    test('arayüzde dile bağlanmamış Türkçe metin kalmadı', () {
      final desen = RegExp(
        r"""(Text\(|label: |tooltip: )'[^']*[çğışöüÇĞİŞÖÜ][^']*'""",
      );
      final kacanlar = <String>[];

      for (final dosya in Directory('lib').listSync(recursive: true)) {
        if (dosya is! File || !dosya.path.endsWith('.dart')) {
          continue;
        }
        if (dosya.path.contains('i18n') || dosya.path.contains('bootstrap')) {
          continue;
        }
        for (final eslesme in desen.allMatches(dosya.readAsStringSync())) {
          kacanlar.add('${dosya.path}: ${eslesme.group(0)}');
        }
      }

      expect(kacanlar, isEmpty, reason: kacanlar.join('\n'));
    });
  });
}
