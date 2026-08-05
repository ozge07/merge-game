import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merge_game/game/ads_controller.dart';
import 'package:merge_game/game/audio_controller.dart';
import 'package:merge_game/game/game_save_store.dart';
import 'package:merge_game/game/high_score_store.dart';
import 'package:merge_game/i18n/app_language.dart';
import 'package:merge_game/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dil kapsamının **Navigator'ın üstünde** olduğunu doğrular.
///
/// Kapsam önce `MaterialApp.home` içine konmuştu. Menü doğru dildeydi ama
/// oyun ekranı Navigator ile açıldığı için kapsamın dışında kalıyor ve cihaz
/// diline düşüyordu: Türkçe seçiliyken HUD İngilizce görünüyordu. Bu test o
/// yapıyı koruyor.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Cihaz dili İngilizce varsayılıyor: kapsam çalışmazsa metinler
    // İngilizceye düşer ve test kırılır.
    LanguageStore.debugOverride = AppLanguage.en;
  });
  tearDown(() => LanguageStore.debugOverride = null);

  testWidgets('Navigator ile açılan oyun ekranı seçilen dili kullanıyor', (
    tester,
  ) async {
    final languages = LanguageStore()..language.value = AppLanguage.tr;

    await tester.pumpWidget(
      MergeApp(
        saves: GameSaveStore(),
        highScores: HighScoreStore(),
        languages: languages,
        ads: AdsController.disabled(),
        audio: AudioController(),
      ),
    );
    await tester.pump();

    // Menü Türkçe.
    expect(find.text('YENİ OYUN'), findsOneWidget);

    await tester.tap(find.text('YENİ OYUN'));
    await tester.pump();
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    // Oyun ekranı da Türkçe olmalı; kapsam Navigator'ın üstünde değilse
    // burada 'SCORE' ve 'HIGHEST' çıkardı.
    expect(find.text('PUAN'), findsOneWidget);
    expect(find.text('EN YÜKSEK'), findsOneWidget);
    expect(find.text('SIRADAKİ'), findsOneWidget);
    expect(find.text('SCORE'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
