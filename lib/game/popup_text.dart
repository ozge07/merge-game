import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Yükselerek sönen yazı: "PERFECT!", "LEVEL 3" gibi mesajlar için.
///
/// Metni her karede yeniden ölçmemek için [TextPainter] bir kez kuruluyor;
/// saydamlık `saveLayer` ile, açılıştaki zıplama `scale` ile veriliyor.
class PopupText extends PositionComponent {
  PopupText({
    required this.text,
    required this.style,
    required super.position,
    this.duration = 0.9,
    this.rise = 90,
    this.popIn = false,
  }) : super(anchor: Anchor.center, priority: 50);

  final String text;
  final TextStyle style;
  final double duration;
  final double rise;

  /// Açılışta elastik bir büyüme — seviye bildirimlerinde kullanılıyor.
  final bool popIn;

  late final TextPainter _painter;
  double _elapsed = 0;

  /// Sönme katmanının boyası; saydamlığı her karede değiştiği için üzerine
  /// yazılıyor.
  final Paint _layerPaint = Paint();

  /// Katmanın sınırları metnin ölçüsüne bağlı, bir kez hesaplanıyor.
  late final Rect _layerBounds = Rect.fromCenter(
    center: Offset.zero,
    width: _painter.width * 2 + 60,
    height: _painter.height * 2 + 60,
  );

  @override
  Future<void> onLoad() async {
    _painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final t = (_elapsed / duration).clamp(0.0, 1.0);
    // Son üçte birde sön.
    final alpha = t < 0.66 ? 1.0 : 1 - (t - 0.66) / 0.34;
    final scale = popIn
        ? 0.6 + Curves.elasticOut.transform(min(1.0, t * 3)) * 0.4
        : 1.0;
    final dy = -rise * Curves.easeOutCubic.transform(t);

    canvas.save();
    canvas.translate(0, dy);
    canvas.scale(scale);

    // `saveLayer` ekran dışı bir tampon ayırıyor — pahalı. Yazı ömrünün ilk
    // üçte ikisinde tamamen opak olduğu için o karelerde katmana hiç gerek yok.
    final fading = alpha < 1;
    if (fading) {
      canvas.saveLayer(
        _layerBounds,
        _layerPaint..color = Colors.white.withValues(
          alpha: alpha.clamp(0.0, 1.0),
        ),
      );
    }
    _painter.paint(canvas, Offset(-_painter.width / 2, -_painter.height / 2));
    if (fading) {
      canvas.restore();
    }
    canvas.restore();
  }
}
