import 'package:flutter/material.dart';

import 'app_language.dart';

/// Ekranda görünen bütün metinler.
///
/// Ayrı bir çeviri paketi ve kod üretimi kullanmıyoruz: oyunda birkaç düzine
/// metin var ve ikisi yan yana durunca çeviriyi gözden kaçırmak zorlaşıyor.
/// Yeni bir metin eklerken iki dili birlikte yazmak zorunda kalıyorsun.
class Strings {
  const Strings(this.language);

  final AppLanguage language;

  /// En yakın [LanguageScope]'tan okur. Dil değişince bu widget'ı kullanan
  /// her yer kendiliğinden yeniden çiziliyor.
  static Strings of(BuildContext context) {
    final kapsam = context
        .dependOnInheritedWidgetOfExactType<_LanguageData>();
    // Kapsam bulunamazsa cihazın diline düşüyoruz; eksik bir sarmalayıcı
    // yüzünden ekran çökmesin.
    return kapsam?.strings ?? Strings(LanguageStore.deviceLanguage());
  }

  String _pick(String tr, String en) =>
      language == AppLanguage.tr ? tr : en;

  // --- Menü ---
  String get titleTop => 'SIDE';
  String get titleBottom => 'GROW';
  String get continueGame => _pick('DEVAM ET', 'CONTINUE');
  String get newGame => _pick('YENİ OYUN', 'NEW GAME');
  String get howToPlay => _pick('NASIL OYNANIR', 'HOW TO PLAY');
  String get exit => _pick('ÇIKIŞ', 'EXIT');
  String get playFirstGame =>
      _pick('ilk oyununu oyna', 'play your first game');
  String record(int best) => _pick('REKOR  $best', 'BEST  $best');
  String get pressBackAgain =>
      _pick('Çıkmak için tekrar geri bas', 'Press back again to exit');

  // --- HUD ---
  String get score => _pick('PUAN', 'SCORE');
  String get highest => _pick('EN YÜKSEK', 'HIGHEST');
  String get nextUp => _pick('SIRADAKİ', 'NEXT');
  String recordSmall(int best) => _pick('rekor $best', 'best $best');
  String get backToMenu => _pick('Menüye dön', 'Back to menu');
  String get soundOn => _pick('Sesi aç', 'Turn sound on');
  String get soundOff => _pick('Sesi kapat', 'Turn sound off');

  // --- Oyun sonu ---
  String get gameOver => _pick('OYUN BİTTİ', 'GAME OVER');
  String get noMovesLeft => _pick('hamle kalmadı', 'no moves left');
  String get points => _pick('puan', 'points');
  String get highestLevel => _pick('En yüksek seviye ', 'Highest level ');
  String get newRecord => _pick('🏆  YENİ REKOR!', '🏆  NEW RECORD!');
  String get watchingAd => _pick('REKLAM AÇILIYOR…', 'LOADING AD…');
  String get continueSubtitle =>
      _pick('tahtada yer aç', 'free up space');
  String get playAgain => _pick('TEKRAR OYNA', 'PLAY AGAIN');
  String get menu => _pick('MENÜ', 'MENU');

  // --- Nasıl oynanır ---
  String get howToTitle => _pick('NASIL OYNANIR', 'HOW TO PLAY');
  String get gotIt => _pick('ANLADIM', 'GOT IT');

  String get ruleTap => _pick(
    'Boş bir kareye dokun, sıradaki obje oraya gelir. Ne geleceğini '
        'üstteki kutuda görürsün.',
    'Tap an empty cell and the next object lands there. The box above '
        'shows what is coming.',
  );

  String get ruleMerge => _pick(
    'Aynı seviyeden iki obje yan yana gelirse birleşip bir üst seviyeye '
        'çıkar. Çapraz komşuluk saymaz.',
    'Two objects of the same level sitting side by side merge into the '
        'next level. Diagonals do not count.',
  );

  String get ruleDrag => _pick(
    'Bir objeyi sürükleyip komşu kareye taşıyabilir, böylece aynı '
        'seviyedekileri buluşturabilirsin.',
    'Drag an object to a neighbouring cell to bring matching levels '
        'together.',
  );

  String get ruleChain => _pick(
    'Birleşme yeni bir komşuluk doğurursa zincir devam eder ve puan '
        'katlanır.',
    'If a merge creates a new neighbour the chain continues and the '
        'points multiply.',
  );

  String get ruleGameOver => _pick(
    'Tahta dolar ve birleşecek komşu kalmazsa oyun biter.',
    'The game ends when the board fills up and no neighbours can merge.',
  );

  // --- Oyun içi tebrikler (Flame tarafında çiziliyor) ---

  /// Yüksek seviyeye ulaşınca çıkan kutlama. [level] oluşan seviye.
  ///
  /// Seviye büyüdükçe mesaj da büyüyor; oyuncu ilerlediğini hissetsin.
  String? mergePraise(int level) => switch (level) {
    5 => _pick('GÜZEL!', 'NICE!'),
    6 => _pick('SÜPER!', 'SUPER!'),
    7 => _pick('HARİKA!', 'GREAT!'),
    8 => _pick('MUHTEŞEM!', 'AWESOME!'),
    9 => _pick('İNANILMAZ!', 'INCREDIBLE!'),
    10 => _pick('EFSANE!', 'LEGENDARY!'),
    >= 11 => _pick('DURDURULAMAZ!', 'UNSTOPPABLE!'),
    _ => null,
  };

  /// Aynı hamlede üst üste birleşme.
  String chainPraise(int chain) =>
      _pick('$chain ZİNCİR!', '$chain CHAIN!');

  // --- Hata ekranı ---
  String get somethingWentWrong => _pick(
    'Bir şeyler ters gitti.\nOyunu kapatıp yeniden açar mısın?',
    'Something went wrong.\nPlease close and reopen the game.',
  );
}

/// Dili ağaca yayar ve değiştiğinde altındaki her şeyi yeniler.
class LanguageScope extends StatelessWidget {
  const LanguageScope({
    required this.store,
    required this.child,
    super.key,
  });

  final LanguageStore store;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: store.language,
      builder: (context, language, _) => _LanguageData(
        strings: Strings(language),
        store: store,
        child: child,
      ),
    );
  }

  /// Dili değiştirmek isteyen düğmeler bunu kullanıyor.
  static LanguageStore storeOf(BuildContext context) {
    final kapsam = context
        .dependOnInheritedWidgetOfExactType<_LanguageData>();
    assert(kapsam != null, 'LanguageScope ağaçta bulunamadı');
    return kapsam!.store;
  }
}

class _LanguageData extends InheritedWidget {
  const _LanguageData({
    required this.strings,
    required this.store,
    required super.child,
  });

  final Strings strings;
  final LanguageStore store;

  @override
  bool updateShouldNotify(_LanguageData oldWidget) =>
      oldWidget.strings.language != strings.language;
}

/// Menüdeki dil düğmesi: TR ile EN arasında geçiş yapıyor.
///
/// İki dil olduğu için açılır liste yerine tek dokunuşluk bir anahtar
/// kullanıyoruz; seçili olan vurgulu duruyor.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final store = LanguageScope.storeOf(context);
    final secili = Strings.of(context).language;

    return Semantics(
      label: secili == AppLanguage.tr
          ? 'Dil: Türkçe. Değiştirmek için dokun.'
          : 'Language: English. Tap to change.',
      button: true,
      child: Material(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: store.toggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final dil in AppLanguage.values)
                  _Chip(language: dil, selected: dil == secili),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.language, required this.selected});

  final AppLanguage language;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFF7FDBFF)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        language.code,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
          color: selected
              ? const Color(0xFF0D1520)
              : Colors.white.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}
