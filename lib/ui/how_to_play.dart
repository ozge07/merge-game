import 'dart:async';

import 'package:flutter/material.dart';

import '../game/merge_game.dart';

/// "Nasıl oynanır" balonu.
///
/// Oyun ilk açıldığında kendiliğinden çıkıyor ve 5 saniye sonra kapanıyor.
/// Oyuncu bilgi düğmesine basarsa tekrar açılıyor.
class HowToPlayTip extends StatefulWidget {
  const HowToPlayTip({required this.onClose, super.key});

  final VoidCallback onClose;

  /// Kendiliğinden kapanma süresi.
  static const Duration autoClose = Duration(seconds: 5);

  @override
  State<HowToPlayTip> createState() => _HowToPlayTipState();
}

class _HowToPlayTipState extends State<HowToPlayTip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..forward();
    _timer = Timer(HowToPlayTip.autoClose, widget.onClose);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        // Balonun dışına dokununca da kapansın.
        onTap: widget.onClose,
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.55),
          child: Center(
            child: FadeTransition(
              opacity: _enter,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.9, end: 1).animate(
                  CurvedAnimation(parent: _enter, curve: Curves.easeOutBack),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2030),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFF7FDBFF),
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'NASIL OYNANIR',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const _Rule(
                          icon: Icons.touch_app_rounded,
                          text:
                              'Boş bir kareye dokun, sıradaki obje oraya '
                              'gelir. Ne geleceğini üstteki kutuda görürsün.',
                        ),
                        const _Rule(
                          icon: Icons.join_full_rounded,
                          text:
                              'Aynı seviyeden iki obje yan yana gelirse '
                              'birleşip bir üst seviyeye çıkar. Çapraz '
                              'komşuluk saymaz.',
                        ),
                        const _Rule(
                          icon: Icons.drag_indicator_rounded,
                          text:
                              'Bir objeyi sürükleyip komşu kareye taşıyabilir, '
                              'böylece aynı seviyedekileri buluşturabilirsin.',
                        ),
                        const _Rule(
                          icon: Icons.bolt_rounded,
                          text:
                              'Birleşme yeni bir komşuluk doğurursa zincir '
                              'devam eder ve puan katlanır.',
                        ),
                        const _Rule(
                          icon: Icons.dangerous_rounded,
                          text:
                              'Tahta dolar ve birleşecek komşu kalmazsa oyun '
                              'biter.',
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: widget.onClose,
                            child: const Text(
                              'ANLADIM',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: Color(0xFF7FDBFF),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.45)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Oyun içindeki yuvarlak bilgi düğmesi.
class InfoButton extends StatelessWidget {
  const InfoButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.07),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: Colors.white54,
          ),
        ),
      ),
    );
  }
}

/// Sıradaki objeyi gösteren küçük satır; hem HUD hem menü kullanıyor.
class NextUpRow extends StatelessWidget {
  const NextUpRow({required this.level, super.key});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'SIRADAKİ',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(width: 10),
        NextTilePreview(level: level),
      ],
    );
  }
}
