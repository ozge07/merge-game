import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../app_log.dart';

/// Yarım kalan oyunu cihazda saklar.
///
/// Menüdeki "Devam et" bu kayda bakıyor: kayıt yoksa düğme hiç çıkmıyor.
class GameSaveStore {
  static const String _key = 'merge_saved_game';

  /// Depolama yanıt vermezse oyunu bekletmeyelim; kayıt olmadan da oynanır.
  static const Duration _timeout = Duration(seconds: 5);

  Map<String, Object?>? _cached;
  bool _loaded = false;

  /// Kayıtlı oyun var mı? [load] çağrıldıktan sonra anlamlı.
  bool get hasSave => _cached != null;

  Map<String, Object?>? get save => _cached;

  Future<void> load() async {
    if (_loaded) {
      return;
    }
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(_timeout);
      final raw = prefs.getString(_key);
      if (raw == null) {
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _cached = decoded;
      }
    } catch (error) {
      AppLog.warn('save', 'kayıtlı oyun okunamadı', error);
    }
  }

  Future<void> write(Map<String, Object?> state) async {
    _cached = state;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(_timeout);
      await prefs.setString(_key, jsonEncode(state)).timeout(_timeout);
    } catch (error) {
      AppLog.warn('save', 'oyun kaydedilemedi', error);
    }
  }

  Future<void> clear() async {
    _cached = null;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(_timeout);
      await prefs.remove(_key).timeout(_timeout);
    } catch (error) {
      AppLog.warn('save', 'kayıt silinemedi', error);
    }
  }
}
