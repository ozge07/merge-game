import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../app_log.dart';

/// Oyunun ses efektleri.
///
/// Sık çalınan sesler için `AudioPool` kullanıyoruz: her seferinde yeni bir
/// oynatıcı kurmak Android'de gözle görülür gecikme yaratıyor.
///
/// Ses açılamazsa (test ortamı, ses aygıtı yok, dosya bulunamadı) hata
/// yutuluyor ve oyun sessiz devam ediyor — ses yüzünden oyun durmamalı.
class AudioController {
  /// Birleşme sesi seviyeye göre tizleşiyor: `merge1..merge8`.
  static const int mergeTones = 8;

  static final List<String> _pooled = [
    'place',
    'drop',
    'invalid',
    'chain',
    'button',
    for (var i = 1; i <= mergeTones; i++) 'merge$i',
  ];

  /// Uzun ve seyrek çalınanlar havuza girmiyor.
  static const List<String> _oneShots = [
    'praise.wav',
    'fanfare.wav',
    'gameover.wav',
  ];

  /// Ses altyapısı yanıt vermezse oyunu bekletmeyelim.
  static const Duration _loadTimeout = Duration(seconds: 8);

  /// Ses açık mı? HUD düğmesi buna bakıyor.
  final ValueNotifier<bool> muted = ValueNotifier<bool>(false);

  final Map<String, AudioPool> _pools = {};
  bool _ready = false;

  Future<void> load() async {
    if (_ready) {
      return;
    }
    try {
      await _loadAll().timeout(_loadTimeout);
      _ready = true;
    } catch (error) {
      _ready = false;
      AppLog.warn('audio', 'ses yüklenemedi, oyun sessiz devam ediyor', error);
    }
  }

  Future<void> _loadAll() async {
    for (final name in _pooled) {
      _pools[name] = await FlameAudio.createPool(
        '$name.wav',
        minPlayers: 1,
        maxPlayers: 3,
      );
    }
    await FlameAudio.audioCache.loadAll(_oneShots);
  }

  void _play(String name, double volume) {
    if (muted.value || !_ready) {
      return;
    }
    final pool = _pools[name];
    if (pool != null) {
      unawaited(pool.start(volume: volume));
    }
  }

  void _oneShot(String file, double volume) {
    if (muted.value || !_ready) {
      return;
    }
    unawaited(FlameAudio.play(file, volume: volume));
  }

  /// Boş kareye yeni obje kondu.
  void place() {
    _play('place', 0.7);
    unawaited(HapticFeedback.selectionClick());
  }

  /// Obje komşu kareye taşındı.
  void drop() => _play('drop', 0.6);

  /// Geçersiz hamle.
  void invalid() => _play('invalid', 0.5);

  /// Birleşme. [level] oluşan yeni seviye; ses onunla birlikte tizleşiyor.
  void merge(int level) {
    _play('merge${level.clamp(1, mergeTones)}', 0.9);
    unawaited(HapticFeedback.lightImpact());
  }

  /// Aynı hamlede üst üste birleşme.
  void chain() => _play('chain', 0.85);

  /// Yüksek seviyeye ulaşıldı.
  void praise() {
    _oneShot('praise.wav', 0.9);
    unawaited(HapticFeedback.mediumImpact());
  }

  /// Çok yüksek seviye: daha görkemli kutlama.
  void fanfare() {
    _oneShot('fanfare.wav', 0.95);
    unawaited(HapticFeedback.heavyImpact());
  }

  void gameOver() {
    _oneShot('gameover.wav', 0.85);
    unawaited(HapticFeedback.heavyImpact());
  }

  /// Menü ve kart düğmeleri.
  void button() => _play('button', 0.6);

  void toggleMute() => muted.value = !muted.value;

  void dispose() {
    muted.dispose();
    for (final pool in _pools.values) {
      unawaited(pool.dispose());
    }
  }
}
