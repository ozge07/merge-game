import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'level_style.dart';

/// Tahtadaki tek bir obje.
///
/// Şekil ve renk seviyeye bağlı; ikisi de yalnızca [level] değişince yeniden
/// hesaplanıyor. Çizimin kendisi karede değişmediği için yol ve boyalar
/// önbellekte tutuluyor — 25 hücrelik tahtada kare başına gereksiz nesne
/// üretmemek için.
class TileComponent extends PositionComponent {
  TileComponent({
    required int level,
    required this.row,
    required this.col,
    required super.position,
    required double side,
    // Alan özel, parametre genel: dışarıdan `level:` diye veriliyor ama
    // içeride setter'dan geçmesi gerekiyor, o yüzden doğrudan bağlanamıyor.
    // ignore: prefer_initializing_formals
  }) : _level = level,
       super(size: Vector2.all(side), anchor: Anchor.center);

  int row;
  int col;

  int _level;

  int get level => _level;

  set level(int value) {
    if (_level == value) {
      return;
    }
    _level = value;
    _invalidate();
  }

  Path? _shape;
  Paint? _bodyPaint;
  Paint? _edgePaint;
  TextPainter? _label;

  void _invalidate() {
    _shape = null;
    _bodyPaint = null;
    _edgePaint = null;
    _label = null;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _invalidate();
  }

  Path get _path {
    final cached = _shape;
    if (cached != null) {
      return cached;
    }
    final rect = Rect.fromLTWH(0, 0, width, height).deflate(width * 0.08);
    final path = Path();
    if (LevelStyle.isCircle(_level)) {
      path.addOval(rect);
    } else {
      final sides = LevelStyle.sidesOf(_level);
      final centre = rect.center;
      final radius = rect.width / 2;
      // Tepesi yukarı baksın diye çeyrek tur geri döndürüyoruz.
      const start = -pi / 2;
      for (var i = 0; i < sides; i++) {
        final angle = start + i * 2 * pi / sides;
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
    }
    return _shape = path;
  }

  Paint get _body {
    final cached = _bodyPaint;
    if (cached != null) {
      return cached;
    }
    final base = LevelStyle.colorOf(_level);
    // Sol üstten gelen ışık: düz renk yerine hafif bir hacim hissi.
    return _bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(base, Colors.white, 0.28)!,
          base,
          Color.lerp(base, Colors.black, 0.24)!,
        ],
        stops: const [0, 0.55, 1],
      ).createShader(Rect.fromLTWH(0, 0, width, height));
  }

  Paint get _edge {
    final cached = _edgePaint;
    if (cached != null) {
      return cached;
    }
    return _edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * 0.035
      ..strokeJoin = StrokeJoin.round
      ..color = Color.lerp(
        LevelStyle.colorOf(_level),
        Colors.black,
        0.45,
      )!.withValues(alpha: 0.75);
  }

  TextPainter get _text {
    final cached = _label;
    if (cached != null) {
      return cached;
    }
    return _label = TextPainter(
      text: TextSpan(
        text: '$_level',
        style: TextStyle(
          fontSize: width * 0.36,
          fontWeight: FontWeight.w900,
          color: Colors.white.withValues(alpha: 0.92),
          shadows: const [Shadow(blurRadius: 4, color: Colors.black38)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void render(Canvas canvas) {
    final path = _path;
    canvas.drawPath(path, _body);
    canvas.drawPath(path, _edge);
    final label = _text;
    label.paint(
      canvas,
      Offset((width - label.width) / 2, (height - label.height) / 2),
    );
  }
}
