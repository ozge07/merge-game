import 'dart:async';

import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

import 'bootstrap.dart';
import 'game/ads_controller.dart';
import 'game/audio_controller.dart';
import 'game/game_save_store.dart';
import 'game/high_score_store.dart';
import 'i18n/app_language.dart';
import 'i18n/strings.dart';
import 'ui/menu_screen.dart';

/// Oyunun zemin rengi; hata ekranı da bununla boyanıyor.
const Color _background = Color(0xFF12161F);

Future<void> main() => bootstrap(() async {
  await Flame.device.setPortrait();

  final saves = GameSaveStore();
  final audio = AudioController();
  final highScores = HighScoreStore();
  final languages = LanguageStore();
  final ads = AdsController();

  // Kayıt, rekor ve dil menü çizilmeden hazır olsun; reklam arka planda.
  await Future.wait([
    saves.load(),
    highScores.load(),
    languages.load(),
    audio.load(),
  ]);
  unawaited(ads.initialise());

  return MergeApp(
    saves: saves,
    highScores: highScores,
    languages: languages,
    audio: audio,
    ads: ads,
  );
}, background: _background);

class MergeApp extends StatelessWidget {
  const MergeApp({
    required this.saves,
    required this.highScores,
    required this.languages,
    required this.audio,
    required this.ads,
    super.key,
  });

  final GameSaveStore saves;
  final HighScoreStore highScores;

  /// Seçilen dil; bütün ekranlar buradan okuyor.
  final LanguageStore languages;

  /// Ses efektleri; oyun ekranına aktarılıyor.
  final AudioController audio;
  final AdsController ads;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Merge Game',
      debugShowCheckedModeBanner: false,
      // Dil kapsamı Navigator'ın üstünde olmalı: `home:` içine konursa
      // sonradan açılan sayfalar kapsamın dışında kalıyor.
      builder: (context, child) =>
          LanguageScope(store: languages, child: child ?? const SizedBox()),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF12161F),
      ),
      home: MenuScreen(
        saves: saves,
        highScores: highScores,
        audio: audio,
        ads: ads,
      ),
    );
  }
}
