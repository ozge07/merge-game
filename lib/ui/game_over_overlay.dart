import 'package:flutter/material.dart';

import '../game/ads_controller.dart';
import '../game/merge_game.dart';

/// Hamle kalmayınca çıkan kart: skor, ulaşılan seviye, reklamla devam,
/// tekrar oyna ve menüye dönüş.
class GameOverOverlay extends StatefulWidget {
  const GameOverOverlay({
    required this.game,
    required this.ads,
    required this.onExitToMenu,
    super.key,
  });

  final MergeGame game;
  final AdsController ads;
  final VoidCallback onExitToMenu;

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  bool _watching = false;

  MergeGame get game => widget.game;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    )..forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  Future<void> _watchAdToContinue() async {
    setState(() => _watching = true);
    final earned = await widget.ads.showRewarded();
    if (!mounted) {
      return;
    }
    setState(() => _watching = false);
    if (earned) {
      game.continueAfterAd();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0, 0.45, curve: Curves.easeOut),
    );
    final pop = CurvedAnimation(parent: _enter, curve: Curves.elasticOut);

    return FadeTransition(
      opacity: fade,
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.66),
        child: Center(
          child: ScaleTransition(
            scale: pop,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Container(
                padding: const EdgeInsets.fromLTRB(26, 26, 26, 22),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2030),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'OYUN BİTTİ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'hamle kalmadı',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: game.score.value),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => Text(
                        '$value',
                        style: const TextStyle(
                          fontSize: 58,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF7FDBFF),
                        ),
                      ),
                    ),
                    Text(
                      'puan',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 2,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'En yüksek seviye ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        NextTilePreview(level: game.highestLevel.value),
                      ],
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: game.beatRecord,
                      builder: (context, beaten, _) => beaten
                          ? const Padding(
                              padding: EdgeInsets.only(top: 14),
                              child: Text(
                                '🏆  YENİ REKOR!',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  color: Color(0xFFFFD54F),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 22),
                    // Devam etme yalnızca bu turda kullanılmadıysa ve
                    // gösterime hazır bir reklam varsa teklif ediliyor.
                    ValueListenableBuilder<bool>(
                      valueListenable: widget.ads.isReady,
                      builder: (context, adReady, _) {
                        if (!adReady || !game.canContinue) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          children: [
                            _CardButton(
                              label: _watching
                                  ? 'REKLAM AÇILIYOR…'
                                  : 'DEVAM ET',
                              subtitle: 'reklam izle, tahtada yer aç',
                              icon: Icons.play_circle_fill_rounded,
                              accent: const Color(0xFF66BB6A),
                              onPressed: _watching ? null : _watchAdToContinue,
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      },
                    ),
                    _CardButton(
                      label: 'TEKRAR OYNA',
                      icon: Icons.refresh_rounded,
                      onPressed: game.startNew,
                    ),
                    const SizedBox(height: 12),
                    _CardButton(
                      label: 'MENÜ',
                      icon: Icons.home_rounded,
                      filled: false,
                      onPressed: widget.onExitToMenu,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  const _CardButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = true,
    this.accent,
    this.subtitle,
  });

  final String label;
  final IconData icon;

  /// `null` ise düğme devre dışı görünüyor (reklam açılırken).
  final VoidCallback? onPressed;
  final bool filled;
  final Color? accent;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? const Color(0xFF0D1520) : Colors.white70;
    final base = accent ?? const Color(0xFF7FDBFF);

    return SizedBox(
      width: double.infinity,
      height: subtitle == null ? 52 : 60,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: filled
              ? LinearGradient(
                  colors: [base, Color.lerp(base, Colors.black, 0.16)!],
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
            borderRadius: BorderRadius.circular(16),
            onTap: onPressed,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: foreground, size: 21),
                    const SizedBox(width: 8),
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
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: foreground.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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
