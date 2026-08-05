import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merge_game/game/ads_controller.dart';
import 'package:merge_game/game/audio_controller.dart';
import 'package:merge_game/game/game_save_store.dart';
import 'package:merge_game/game/high_score_store.dart';
import 'package:merge_game/game/merge_board.dart';
import 'package:merge_game/game/merge_game.dart';
import 'package:merge_game/game/popup_text.dart';
import 'package:merge_game/ui/game_page.dart';
import 'package:merge_game/i18n/app_language.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Oyunu gerçek `GameWidget` içinde kurar; Flame'in bütün yaşam döngüsü
/// çalışsın diye birkaç kare çeviriyoruz.
Future<MergeGame> pumpGame(WidgetTester tester) async {
  final saves = GameSaveStore();
  final highScores = HighScoreStore();
  final game = MergeGame(
    random: Random(3),
    saves: saves,
    highScores: highScores,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: GamePage(
        saves: saves,
        highScores: highScores,
        ads: AdsController.disabled(),
        audio: AudioController(),
        game: game,
      ),
    ),
  );
  // GameWidget ilk karede yüklenmiyor; onLoad bitene kadar çeviriyoruz.
  for (var i = 0; i < 20 && !game.isLoaded; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  expect(game.isLoaded, isTrue, reason: 'oyun yüklenemedi');
  // Katmanlar (HUD) oyun yüklendikten bir kare sonra ağaca giriyor.
  await tester.pump();
  return game;
}

/// Sonsuz animasyon olmadığı için pumpAndSettle güvenli, yine de efektlerin
/// bitmesini beklemek için sabit süre çeviriyoruz.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  // Depolama eklentisi test ortamında gerçek değil; sahte değerlerle
  // beslemezsek çağrılar askıda kalıp testleri yavaşlatıyor.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Testler Türkçe metinlere bakıyor; cihaz dilinden bağımsız olsun.
    LanguageStore.debugOverride = AppLanguage.tr;
  });
  tearDown(() => LanguageStore.debugOverride = null);

  testWidgets('oyun açılıyor ve tahta boş başlıyor', (tester) async {
    final game = await pumpGame(tester);

    expect(find.byType(GameWidget<MergeGame>), findsOneWidget);
    expect(game.board.filledCount, 0);
    expect(game.score.value, 0);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('skor ve sıradaki obje ekranda görünüyor', (tester) async {
    await pumpGame(tester);

    expect(find.text('PUAN'), findsOneWidget);
    expect(find.text('EN YÜKSEK'), findsOneWidget);
    expect(find.text('SIRADAKİ'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('hücreye dokununca obje beliriyor', (tester) async {
    final game = await pumpGame(tester);

    game.tapCell(2, 2);
    await settle(tester);

    expect(game.board.levelAt(2, 2), isNotNull);
    expect(game.board.filledCount, 1);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('birleşme skoru ekrana yansıyor', (tester) async {
    final game = await pumpGame(tester);

    game.board.debugSet(0, 0, 3);
    game.board.debugSet(1, 1, 3);
    game.dropTile(1, 1, 0, 1);
    await settle(tester);

    expect(game.board.levelAt(0, 1), 4);
    expect(game.score.value, greaterThan(0));
    expect(find.text('${game.score.value}'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('geçersiz sürükleme reddediliyor', (tester) async {
    final game = await pumpGame(tester);

    game.board.debugSet(1, 1, 2);
    game.board.debugSet(1, 2, 5);

    expect(game.dropTile(1, 2, 1, 1), isFalse, reason: 'farklı seviye');
    expect(game.dropTile(1, 1, 3, 3), isFalse, reason: 'komşu değil');
    expect(game.board.levelAt(1, 1), 2);
    expect(game.board.levelAt(1, 2), 5);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('tahta dolunca oyun sonu kartı çıkıyor', (tester) async {
    final game = await pumpGame(tester);

    // Son hücre hariç her yeri komşusundan farklı seviyeyle dolduruyoruz.
    for (var row = 0; row < game.board.size; row++) {
      for (var col = 0; col < game.board.size; col++) {
        if (row == 4 && col == 4) {
          continue;
        }
        game.board.debugSet(row, col, (row + col) % 2 == 0 ? 6 : 9);
      }
    }
    game.tapCell(4, 4);
    await settle(tester);

    expect(game.isOver.value, isTrue);
    expect(find.text('OYUN BİTTİ'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('tekrar oyna tahtayı temizliyor', (tester) async {
    final game = await pumpGame(tester);

    for (var row = 0; row < game.board.size; row++) {
      for (var col = 0; col < game.board.size; col++) {
        if (row == 4 && col == 4) {
          continue;
        }
        game.board.debugSet(row, col, (row + col) % 2 == 0 ? 6 : 9);
      }
    }
    game.tapCell(4, 4);
    await settle(tester);
    expect(find.text('OYUN BİTTİ'), findsOneWidget);

    await tester.tap(find.text('TEKRAR OYNA'));
    await settle(tester);

    expect(game.isOver.value, isFalse);
    expect(game.board.filledCount, 0);
    expect(find.text('OYUN BİTTİ'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('oyun bitince yeni obje konmuyor', (tester) async {
    final game = await pumpGame(tester);

    for (var row = 0; row < game.board.size; row++) {
      for (var col = 0; col < game.board.size; col++) {
        if (row == 4 && col == 4) {
          continue;
        }
        game.board.debugSet(row, col, (row + col) % 2 == 0 ? 6 : 9);
      }
    }
    game.tapCell(4, 4);
    await settle(tester);

    final before = game.board.filledCount;
    game.tapCell(0, 0);
    expect(game.board.filledCount, before);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  group('hücre koordinatı', () {
    testWidgets('tahtanın dışına dokunuş yok sayılıyor', (tester) async {
      final game = await pumpGame(tester);

      expect(game.cellAt(Vector2(-50, -50)), isNull);
      expect(game.cellAt(Vector2(MergeGame.worldWidth + 50, 10)), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('hücre merkezi kendi hücresine çözülüyor', (tester) async {
      final game = await pumpGame(tester);

      for (final cell in const [(0, 0), (2, 3), (4, 4)]) {
        final centre = game.centreOf(cell.$1, cell.$2);
        expect(game.cellAt(centre), cell);
      }

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  testWidgets('en üst seviyede birleşme durduğu için oyun kilitlenmiyor', (
    tester,
  ) async {
    final game = await pumpGame(tester);

    game.board.debugSet(0, 0, MergeBoard.maxLevel);
    game.board.debugSet(0, 1, MergeBoard.maxLevel);

    expect(game.dropTile(0, 1, 0, 0), isFalse);
    expect(game.board.levelAt(0, 0), MergeBoard.maxLevel);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('oyun içinde bilgi ve menü düğmeleri var', (tester) async {
    await pumpGame(tester);

    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('bilgi düğmesi nasıl oynanır balonunu açıyor', (tester) async {
    await pumpGame(tester);
    expect(find.text('NASIL OYNANIR'), findsNothing);

    await tester.tap(find.byIcon(Icons.info_outline_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('NASIL OYNANIR'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('balon 5 saniye sonra kendiliğinden kapanıyor', (tester) async {
    await pumpGame(tester);

    await tester.tap(find.byIcon(Icons.info_outline_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('NASIL OYNANIR'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('NASIL OYNANIR'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('boşta kalınca ipucu beliriyor, hamle yapınca sönüyor', (
    tester,
  ) async {
    final game = await pumpGame(tester);

    game.tapCell(0, 0);
    game.tapCell(0, 2);
    await settle(tester);
    expect(game.activeHint, isNull);

    // Boşta geçen süreyi kare kare ilerletiyoruz.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(game.activeHint, isNotNull, reason: '10 saniye sonra çıkmalı');

    game.tapCell(4, 4);
    await settle(tester);
    expect(game.activeHint, isNull, reason: 'hamle ipucunu sıfırlamalı');

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reklamla devam tahtada yer açıp oyunu sürdürüyor', (
    tester,
  ) async {
    final game = await pumpGame(tester);

    for (var row = 0; row < game.board.size; row++) {
      for (var col = 0; col < game.board.size; col++) {
        if (row == 4 && col == 4) {
          continue;
        }
        game.board.debugSet(row, col, (row + col) % 2 == 0 ? 6 : 9);
      }
    }
    game.tapCell(4, 4);
    await settle(tester);
    expect(game.isOver.value, isTrue);
    expect(game.canContinue, isTrue);

    game.continueAfterAd();
    await settle(tester);

    expect(game.isOver.value, isFalse);
    expect(game.board.isFull, isFalse, reason: 'yer açılmalı');
    expect(game.canContinue, isFalse, reason: 'tur başına bir kez');

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('kayıtlı oyundan devam edilince tahta geri geliyor', (
    tester,
  ) async {
    final game = await pumpGame(tester);

    game.tapCell(0, 0);
    game.tapCell(2, 3);
    game.tapCell(4, 1);
    await settle(tester);
    final beklenen = [
      for (var r = 0; r < game.board.size; r++)
        [for (var c = 0; c < game.board.size; c++) game.board.levelAt(r, c)],
    ];
    final kayit = game.board.toJson();
    final puan = game.score.value;

    await tester.pumpWidget(const SizedBox.shrink());

    // Yeni bir oyun kurup aynı kaydı yüklüyoruz.
    final saves = GameSaveStore();
    await saves.write(kayit);
    final ikinci = MergeGame(
      random: Random(3),
      saves: saves,
      resumeOnLoad: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: GamePage(
          saves: saves,
          highScores: HighScoreStore(),
          ads: AdsController.disabled(),
        audio: AudioController(),
          game: ikinci,
          resume: true,
        ),
      ),
    );
    for (var i = 0; i < 20 && !ikinci.isLoaded; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump();
    await settle(tester);

    expect(ikinci.score.value, puan);
    for (var r = 0; r < ikinci.board.size; r++) {
      for (var c = 0; c < ikinci.board.size; c++) {
        expect(ikinci.board.levelAt(r, c), beklenen[r][c]);
      }
    }

    await tester.pumpWidget(const SizedBox.shrink());
  });

  group('ses ve tebrik', () {
    testWidgets('HUD ses düğmesi sesi kapatıp açıyor', (tester) async {
      final game = await pumpGame(tester);
      expect(game.audio.muted.value, isFalse);

      await tester.tap(find.byIcon(Icons.volume_up));
      await tester.pump();

      expect(game.audio.muted.value, isTrue);
      expect(find.byIcon(Icons.volume_off), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('yüksek seviye birleşmesi ekrana tebrik yazıyor', (
      tester,
    ) async {
      final game = await pumpGame(tester);
      // Tebrik metinlerini elle bağlıyoruz; normalde arayüz veriyor.
      game.mergePraiseText = (level) => level >= 5 ? 'TEBRIK$level' : null;

      // Yan yana iki seviye 5 objesi: birleşince 6 olur ve tebrik çıkar.
      game.board.debugSet(0, 0, 5);
      game.board.debugSet(1, 1, 5);
      game.dropTile(1, 1, 0, 1);
      await settle(tester);

      final yazilar = game.world.children.whereType<PopupText>().toList();
      expect(yazilar, isNotEmpty, reason: 'tebrik yazısı eklenmeli');
      expect(yazilar.first.text, 'TEBRIK6');

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('düşük seviye birleşmesinde tebrik çıkmıyor', (tester) async {
      final game = await pumpGame(tester);
      game.mergePraiseText = (level) => level >= 5 ? 'TEBRIK$level' : null;

      game.board.debugSet(0, 0, 1);
      game.board.debugSet(1, 1, 1);
      game.dropTile(1, 1, 0, 1);
      await settle(tester);

      expect(game.world.children.whereType<PopupText>(), isEmpty);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
