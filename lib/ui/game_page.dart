import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/ads_controller.dart';
import '../game/audio_controller.dart';
import '../game/game_save_store.dart';
import '../game/high_score_store.dart';
import '../game/merge_game.dart';
import '../i18n/strings.dart';
import 'game_over_overlay.dart';
import 'how_to_play.dart';
import 'hud_overlay.dart';

/// Oyun ekranı: Flame tuvali ve üstündeki Flutter katmanları.
class GamePage extends StatefulWidget {
  const GamePage({
    required this.saves,
    required this.highScores,
    required this.audio,
    required this.ads,
    this.resume = false,
    this.game,
    super.key,
  });

  final GameSaveStore saves;
  final HighScoreStore highScores;
  final AudioController audio;
  final AdsController ads;

  /// `true` ise kayıtlı oyundan devam edilir.
  final bool resume;

  /// Testlerin sabit tohumlu bir oyun verebilmesi için.
  final MergeGame? game;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final MergeGame _game =
      widget.game ??
      MergeGame(
        saves: widget.saves,
        highScores: widget.highScores,
        audio: widget.audio,
        resumeOnLoad: widget.resume,
      );

  bool _showHowTo = false;

  @override
  void initState() {
    super.initState();
    // Oyun sonu katmanını build içinde açıp kapatmak yanlış olurdu: overlay
    // eklemek çizim sırasında yeniden çizim isteği demek. Durumu dinliyoruz.
    _game.isOver.addListener(_onOverChanged);
    // Açılıştaki deneme başarısız olmuş olabilir; her oyunda tazeliyoruz.
    unawaited(widget.ads.initialise());
  }

  @override
  void dispose() {
    _game.isOver.removeListener(_onOverChanged);
    super.dispose();
  }

  void _onOverChanged() {
    if (_game.isOver.value) {
      _game.overlays.add('gameOver');
    } else {
      _game.overlays.remove('gameOver');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tebrik metinleri Flame tarafında çiziliyor; dil değişince güncelliyoruz.
    final metin = Strings.of(context);
    _game.mergePraiseText = metin.mergePraise;
    _game.chainPraiseText = metin.chainPraise;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12161F),
      body: Stack(
        children: [
          Positioned.fill(
            child: GameWidget<MergeGame>(
              game: _game,
              loadingBuilder: (context) => const SizedBox.shrink(),
              overlayBuilderMap: {
                // Katman oyun tuvalinden bağımsız rasterlensin.
                'hud': (context, game) => RepaintBoundary(
                  child: HudOverlay(
                  game: game,
                  onInfo: () => setState(() => _showHowTo = true),
                    onMenu: () => Navigator.of(context).maybePop(),
                  ),
                ),
                'gameOver': (context, game) => GameOverOverlay(
                  game: game,
                  ads: widget.ads,
                  onExitToMenu: () => Navigator.of(context).maybePop(),
                ),
              },
              initialActiveOverlays: const ['hud'],
            ),
          ),
          if (_showHowTo)
            HowToPlayTip(onClose: () => setState(() => _showHowTo = false)),
        ],
      ),
    );
  }
}
