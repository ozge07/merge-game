import 'package:flutter/material.dart';

import '../game/merge_game.dart';
import 'how_to_play.dart';

/// Ekranın üstündeki skor, rekor, sıradaki obje ve düğmeler.
class HudOverlay extends StatelessWidget {
  const HudOverlay({
    required this.game,
    required this.onInfo,
    required this.onMenu,
    super.key,
  });

  final MergeGame game;
  final VoidCallback onInfo;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ValueListenableBuilder<int>(
                    valueListenable: game.score,
                    builder: (context, score, _) =>
                        _Stat(label: 'PUAN', value: '$score'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ValueListenableBuilder<int>(
                    valueListenable: game.highestLevel,
                    builder: (context, level, _) =>
                        _Stat(label: 'EN YÜKSEK', value: '$level'),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  children: [
                    InfoButton(onPressed: onInfo),
                    const SizedBox(height: 8),
                    _RoundButton(
                      icon: Icons.home_rounded,
                      tooltip: 'Menüye dön',
                      onPressed: onMenu,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder<int>(
              valueListenable: game.nextLevel,
              builder: (context, level, _) => NextUpRow(level: level),
            ),
            const SizedBox(height: 6),
            ValueListenableBuilder<int>(
              valueListenable: game.highScores.best,
              builder: (context, best, _) => best == 0
                  ? const SizedBox.shrink()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.emoji_events_rounded,
                          size: 14,
                          color: Color(0xFFFFD54F),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'rekor $best',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              height: 1.1,
              fontWeight: FontWeight.w900,
              color: Color(0xFF7FDBFF),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.07),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 20, color: Colors.white54),
          ),
        ),
      ),
    );
  }
}
