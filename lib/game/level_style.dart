import 'package:flutter/material.dart';

/// Seviye başına renk ve şekil.
///
/// Renk merdiveni bilerek doygun ve sıcaktan soğuğa gidiyor: oyuncu iki objeyi
/// yan yana koyduğunda aynı seviyede olup olmadığını okumadan, renkten
/// anlayabilmeli. Renk körlüğü olanlar için ayrıca her seviyenin kenar sayısı
/// farklı — üçgenden daireye doğru gidiyor.
class LevelStyle {
  const LevelStyle._();

  static const List<Color> _colors = [
    Color(0xFF4DD0E1), // 1
    Color(0xFF4FC3F7), // 2
    Color(0xFF7986CB), // 3
    Color(0xFF9575CD), // 4
    Color(0xFFBA68C8), // 5
    Color(0xFFF06292), // 6
    Color(0xFFE57373), // 7
    Color(0xFFFF8A65), // 8
    Color(0xFFFFB74D), // 9
    Color(0xFFFFD54F), // 10
    Color(0xFFAED581), // 11
  ];

  /// Seviye 1'den başlıyor; listenin dışına taşarsa son renkte kalıyor.
  static Color colorOf(int level) =>
      _colors[(level - 1).clamp(0, _colors.length - 1)];

  /// Kaç kenarlı çizileceği. 3'ten başlayıp artıyor, 8'den sonra daire.
  static int sidesOf(int level) => 2 + level;

  /// Sekiz kenardan sonra çokgen yerine daire çiziyoruz; daha fazlası zaten
  /// daireden ayırt edilemiyor.
  static bool isCircle(int level) => sidesOf(level) > 8;
}
