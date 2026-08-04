import 'dart:async';

import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

import 'game/ads_controller.dart';
import 'game/game_save_store.dart';
import 'game/high_score_store.dart';
import 'ui/menu_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.setPortrait();

  final saves = GameSaveStore();
  final highScores = HighScoreStore();
  final ads = AdsController();

  // Kayıt ve rekor menü çizilmeden hazır olsun; reklam arka planda yüklensin.
  await Future.wait([saves.load(), highScores.load()]);
  unawaited(ads.initialise());

  runApp(MergeApp(saves: saves, highScores: highScores, ads: ads));
}

class MergeApp extends StatelessWidget {
  const MergeApp({
    required this.saves,
    required this.highScores,
    required this.ads,
    super.key,
  });

  final GameSaveStore saves;
  final HighScoreStore highScores;
  final AdsController ads;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Merge Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF12161F),
      ),
      home: MenuScreen(saves: saves, highScores: highScores, ads: ads),
    );
  }
}
