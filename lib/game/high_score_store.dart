import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_log.dart';

/// En yüksek puanı cihazda saklar.
class HighScoreStore {
  static const String _key = 'merge_high_score';

  /// Depolama yanıt vermezse oyunu bekletmeyelim.
  static const Duration _timeout = Duration(seconds: 5);

  /// Menü ve HUD bunu dinliyor.
  final ValueNotifier<int> best = ValueNotifier<int>(0);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(_timeout);
      best.value = prefs.getInt(_key) ?? 0;
    } catch (error) {
      AppLog.warn('score', 'rekor okunamadı', error);
    }
  }

  /// [score] rekoru geçtiyse saklar ve `true` döner.
  Future<bool> submit(int score) async {
    if (score <= best.value) {
      return false;
    }
    best.value = score;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(_timeout);
      await prefs.setInt(_key, score).timeout(_timeout);
    } catch (error) {
      AppLog.warn('score', 'rekor kaydedilemedi', error);
    }
    return true;
  }

  void dispose() => best.dispose();
}
