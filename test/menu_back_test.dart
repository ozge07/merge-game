import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merge_game/game/ads_controller.dart';
import 'package:merge_game/game/audio_controller.dart';
import 'package:merge_game/game/game_save_store.dart';
import 'package:merge_game/game/high_score_store.dart';
import 'package:merge_game/i18n/app_language.dart';
import 'package:merge_game/i18n/strings.dart';
import 'package:merge_game/ui/menu_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Menüde geri tuşu davranışı ve dil düğmesi.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Testler Türkçe metinlere bakıyor; cihaz dilinden bağımsız olsun.
    LanguageStore.debugOverride = AppLanguage.tr;
  });
  tearDown(() => LanguageStore.debugOverride = null);

  /// Menüyü gerçek dil kapsamıyla kurar.
  Future<LanguageStore> pumpMenu(WidgetTester tester) async {
    final languages = LanguageStore();
    await tester.pumpWidget(
      MaterialApp(
        home: LanguageScope(
          store: languages,
          child: MenuScreen(
            saves: GameSaveStore(),
            highScores: HighScoreStore(),
            ads: AdsController.disabled(),
        audio: AudioController(),
          ),
        ),
      ),
    );
    await tester.pump();
    return languages;
  }

  /// Sistemin geri tuşunu taklit eder.
  Future<void> geriBas(WidgetTester tester) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
      (_) {},
    );
    await tester.pump();
  }

  testWidgets('tek geri tuşu uyarı gösteriyor, uygulamayı kapatmıyor', (
    tester,
  ) async {
    await pumpMenu(tester);

    await geriBas(tester);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Çıkmak için tekrar geri bas'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  group('dil seçimi', () {
    testWidgets('menü Türkçe açılıyor ve dil düğmesi görünüyor', (
      tester,
    ) async {
      await pumpMenu(tester);

      expect(find.text('YENİ OYUN'), findsOneWidget);
      expect(find.text('NASIL OYNANIR'), findsOneWidget);
      // ÇIKIŞ düğmesi yalnızca Android'de çiziliyor; testler masaüstünde koşuyor.
      expect(find.text('TR'), findsOneWidget);
      expect(find.text('EN'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('düğmeye basınca metinler İngilizceye dönüyor', (
      tester,
    ) async {
      await pumpMenu(tester);

      await tester.tap(find.text('EN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('NEW GAME'), findsOneWidget);
      expect(find.text('HOW TO PLAY'), findsOneWidget);
      expect(find.text('YENİ OYUN'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('tekrar basınca Türkçeye dönüyor', (tester) async {
      await pumpMenu(tester);

      await tester.tap(find.text('EN'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('NEW GAME'), findsOneWidget);

      await tester.tap(find.text('TR'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('YENİ OYUN'), findsOneWidget);
      expect(find.text('NEW GAME'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('seçim cihazda saklanıyor', (tester) async {
      final languages = await pumpMenu(tester);

      await tester.tap(find.text('EN'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpWidget(const SizedBox.shrink());

      // Yeni bir depo aynı kaydı okumalı.
      final yeniden = LanguageStore();
      await yeniden.load();

      expect(languages.language.value, AppLanguage.en);
      expect(yeniden.language.value, AppLanguage.en);
    });
  });
}
