import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/ads_controller.dart';
import '../game/game_save_store.dart';
import '../game/high_score_store.dart';
import '../game/level_style.dart';
import 'game_page.dart';
import 'how_to_play.dart';

/// Ana menü: yeni oyun, kaldığı yerden devam, nasıl oynanır ve çıkış.
class MenuScreen extends StatefulWidget {
  const MenuScreen({
    required this.saves,
    required this.highScores,
    required this.ads,
    super.key,
  });

  final GameSaveStore saves;
  final HighScoreStore highScores;
  final AdsController ads;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;
  bool _showHowTo = false;

  @override
  void initState() {
    super.initState();
    // Arka plandaki objeler yavaşça süzülüyor; menü durağan görünmesin.
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  Future<void> _play({required bool resume}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GamePage(
          saves: widget.saves,
          highScores: widget.highScores,
          ads: widget.ads,
          resume: resume,
        ),
      ),
    );
    // Oyundan dönünce "devam et" düğmesinin durumu değişmiş olabilir.
    if (mounted) {
      setState(() {});
    }
  }

  void _quit() {
    // Android'de uygulamayı kapatmanın desteklenen yolu bu; iOS'ta Apple
    // kendi kendine kapanmayı istemiyor, o yüzden orada düğmeyi göstermiyoruz.
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final hasSave = widget.saves.hasSave;

    return Scaffold(
      backgroundColor: const Color(0xFF12161F),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _drift,
              builder: (context, _) =>
                  CustomPaint(painter: _MenuBackdrop(_drift.value)),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  const Text(
                    'MERGE',
                    style: TextStyle(
                      fontSize: 52,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'GAME',
                    style: TextStyle(
                      fontSize: 52,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                      color: Color(0xFF7FDBFF),
                      shadows: [
                        Shadow(blurRadius: 24, color: Color(0x807FDBFF)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  ValueListenableBuilder<int>(
                    valueListenable: widget.highScores.best,
                    builder: (context, best, _) => _RecordBadge(best: best),
                  ),
                  const Spacer(),
                  if (hasSave) ...[
                    _MenuButton(
                      label: 'DEVAM ET',
                      icon: Icons.play_circle_fill_rounded,
                      filled: true,
                      onPressed: () => _play(resume: true),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _MenuButton(
                    label: 'YENİ OYUN',
                    icon: Icons.play_arrow_rounded,
                    filled: !hasSave,
                    onPressed: () => _play(resume: false),
                  ),
                  const SizedBox(height: 12),
                  _MenuButton(
                    label: 'NASIL OYNANIR',
                    icon: Icons.info_outline_rounded,
                    filled: false,
                    onPressed: () => setState(() => _showHowTo = true),
                  ),
                  if (Platform.isAndroid) ...[
                    const SizedBox(height: 12),
                    _MenuButton(
                      label: 'ÇIKIŞ',
                      icon: Icons.close_rounded,
                      filled: false,
                      onPressed: _quit,
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          if (_showHowTo)
            HowToPlayTip(onClose: () => setState(() => _showHowTo = false)),
        ],
      ),
    );
  }
}

class _RecordBadge extends StatelessWidget {
  const _RecordBadge({required this.best});

  final int best;

  @override
  Widget build(BuildContext context) {
    if (best == 0) {
      return Text(
        'ilk oyununu oyna',
        style: TextStyle(
          fontSize: 13,
          letterSpacing: 1,
          color: Colors.white.withValues(alpha: 0.35),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            size: 18,
            color: Color(0xFFFFD54F),
          ),
          const SizedBox(width: 10),
          Text(
            'REKOR  $best',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: Color(0xFFFFD54F),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? const Color(0xFF0D1520) : Colors.white70;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: filled
              ? const LinearGradient(
                  colors: [Color(0xFF7FDBFF), Color(0xFF4FC3F7)],
                )
              : null,
          color: filled ? null : Colors.white.withValues(alpha: 0.06),
          border: filled
              ? null
              : Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 2,
                ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: foreground, size: 22),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Menü arka planında yavaşça süzülen objeler.
class _MenuBackdrop extends CustomPainter {
  _MenuBackdrop(this.t);

  /// 0..1 arası serbest akan faz.
  final double t;

  /// (x oranı, y oranı, boyut oranı, seviye) — elle dağıtıldı ki
  /// başlık ve düğmelerin arkasında düzgün dursunlar.
  static const List<(double, double, double, int)> _shapes = [
    (0.12, 0.10, 0.13, 1),
    (0.82, 0.14, 0.10, 3),
    (0.20, 0.30, 0.08, 5),
    (0.90, 0.34, 0.12, 2),
    (0.08, 0.62, 0.11, 7),
    (0.88, 0.68, 0.09, 4),
    (0.28, 0.86, 0.10, 6),
    (0.74, 0.90, 0.12, 8),
  ];

  /// Renkler fazdan bağımsız, her karede yeniden hesaplanmasın.
  static final List<Color> _colours = [
    for (final shape in _shapes)
      LevelStyle.colorOf(shape.$4).withValues(alpha: 0.16),
  ];

  static final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _shapes.length; i++) {
      final (xRatio, yRatio, sizeRatio, level) = _shapes[i];
      final bob = sin(t * 2 * pi + i * 0.8) * size.height * 0.012;
      final side = size.width * sizeRatio;
      final centre = Offset(
        size.width * xRatio,
        size.height * yRatio + bob,
      );
      final rect = Rect.fromCenter(
        center: centre,
        width: side,
        height: side,
      );

      canvas.save();
      canvas.translate(centre.dx, centre.dy);
      canvas.rotate(sin(t * 2 * pi + i) * 0.12);
      canvas.translate(-centre.dx, -centre.dy);
      canvas.drawPath(
        _pathFor(rect, level),
        _paint..color = _colours[i],
      );
      canvas.restore();
    }
  }

  /// Oyundakiyle aynı şekil merdiveni: seviye arttıkça kenar sayısı artıyor.
  Path _pathFor(Rect rect, int level) {
    final path = Path();
    if (LevelStyle.isCircle(level)) {
      path.addOval(rect);
      return path;
    }
    final sides = LevelStyle.sidesOf(level);
    final centre = rect.center;
    final radius = rect.width / 2;
    for (var i = 0; i < sides; i++) {
      final angle = -pi / 2 + i * 2 * pi / sides;
      final point = Offset(
        centre.dx + cos(angle) * radius,
        centre.dy + sin(angle) * radius,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_MenuBackdrop oldDelegate) => oldDelegate.t != t;
}
