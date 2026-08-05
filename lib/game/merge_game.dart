import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'audio_controller.dart';
import 'game_save_store.dart';
import 'high_score_store.dart';
import 'level_style.dart';
import 'merge_board.dart';
import 'popup_text.dart';
import 'tile_component.dart';

/// Birleştirme oyununun Flame tarafı.
///
/// Kuralların tamamı [MergeBoard] içinde; burada yalnızca dokunuşu hücreye
/// çeviriyor, modeli çağırıyor ve sonucu ekrana yansıtıyoruz.
class MergeGame extends FlameGame {
  MergeGame({
    Random? random,
    GameSaveStore? saves,
    HighScoreStore? highScores,
    AudioController? audio,
    this.resumeOnLoad = false,
  }) : board = MergeBoard(random: random),
       saves = saves ?? GameSaveStore(),
       highScores = highScores ?? HighScoreStore(),
       audio = audio ?? AudioController();

  /// Açılışta kayıtlı oyundan mı devam edilecek?
  ///
  /// Kararın yükleme anında verilmesi şart: [startNew] kaydı siliyor, önce o
  /// çalışırsa geri yüklenecek bir şey kalmıyor.
  final bool resumeOnLoad;

  /// Tasarım genişliği. Kamera bunu ekran genişliğine oturtuyor, böylece
  /// bütün ölçüler telefondan bağımsız.
  static const double worldWidth = 500;

  /// Oyuncu bu kadar saniye hamle yapmazsa ipucu yanıp sönmeye başlıyor.
  static const double idleDelay = 10;

  static const double _margin = 18;
  static const double _gap = 10;

  final MergeBoard board;
  final GameSaveStore saves;
  final HighScoreStore highScores;
  final AudioController audio;

  final BoardComponent _boardComponent = BoardComponent();

  /// Ekranın dünya koordinatındaki yüksekliği; kameradan hesaplanıyor.
  double worldHeight = 900;

  final ValueNotifier<int> score = ValueNotifier<int>(0);
  final ValueNotifier<int> highestLevel = ValueNotifier<int>(0);
  final ValueNotifier<int> nextLevel = ValueNotifier<int>(1);
  final ValueNotifier<bool> isOver = ValueNotifier<bool>(false);

  /// Bu turda rekor kırıldı mı? Oyun sonu kartı buna göre kutluyor.
  final ValueNotifier<bool> beatRecord = ValueNotifier<bool>(false);

  /// Tebrik metinlerini üreten geri çağrı; arayüz dil değişince güncelliyor.
  ///
  /// Oyun sınıfı widget ağacına bağlı olmadığı için `BuildContext`
  /// kullanamıyor; metinleri dışarıdan alıyor.
  String? Function(int level) mergePraiseText = (_) => null;
  String Function(int chain) chainPraiseText = (chain) => '$chain';

  /// Yanıp sönen öneri; oyuncu hamle yapınca sıfırlanıyor.
  MergeHint? activeHint;

  /// İpucunun nefes alma fazı.
  double hintPhase = 0;

  double _idleSeconds = 0;

  /// Reklamla devam etme tur başına bir kez.
  bool _usedContinue = false;

  bool get canContinue => !_usedContinue;

  /// Bir hücrenin kenar uzunluğu.
  double get cellSide =>
      (worldWidth - _margin * 2 - _gap * (board.size - 1)) / board.size;

  double get boardSide => worldWidth - _margin * 2;

  /// Tahtanın sol üst köşesi. Dikeyde ortadan biraz aşağıda: üstte skor,
  /// altta sıradaki obje için yer kalsın.
  Vector2 get boardOrigin => Vector2(_margin, (worldHeight - boardSide) * 0.54);

  @override
  Color backgroundColor() => const Color(0xFF12161F);

  @override
  Future<void> onLoad() async {
    _applyCamera(size);
    await world.add(_boardComponent);
    if (!resumeOnLoad || !resumeSaved()) {
      startNew();
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _applyCamera(size);
    if (isLoaded) {
      _boardComponent.layout();
    }
  }

  void _applyCamera(Vector2 size) {
    if (size.x <= 0 || size.y <= 0) {
      return;
    }
    // Sabit genişlik: tahta her telefonda ekranı aynı oranda dolduruyor.
    camera.viewfinder.zoom = size.x / worldWidth;
    camera.viewfinder.anchor = Anchor.topLeft;
    worldHeight = size.y / camera.viewfinder.zoom;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isOver.value) {
      return;
    }
    _idleSeconds += dt;
    if (activeHint == null && _idleSeconds >= idleDelay) {
      activeHint = board.findHint();
      hintPhase = 0;
    }
    if (activeHint != null) {
      hintPhase += dt * 3.4;
    }
  }

  /// Hücrenin merkezinin dünya koordinatı.
  Vector2 centreOf(int row, int col) {
    final origin = boardOrigin;
    final side = cellSide;
    return Vector2(
      origin.x + col * (side + _gap) + side / 2,
      origin.y + row * (side + _gap) + side / 2,
    );
  }

  /// Dünya koordinatını hücreye çevirir; tahtanın dışındaysa `null`.
  (int, int)? cellAt(Vector2 point) {
    final origin = boardOrigin;
    final step = cellSide + _gap;
    final col = ((point.x - origin.x) / step).floor();
    final row = ((point.y - origin.y) / step).floor();
    if (row < 0 || row >= board.size || col < 0 || col >= board.size) {
      return null;
    }
    // Hücreler arasındaki boşluğa denk gelen dokunuşları da en yakın hücreye
    // sayıyoruz; parmakla oynanan bir oyunda bu daha affedici.
    return (row, col);
  }

  /// Sıfırdan yeni oyun.
  void startNew() {
    board.reset();
    _boardComponent.clearTiles();
    _usedContinue = false;
    beatRecord.value = false;
    isOver.value = false;
    _clearHint();
    _publish();
    unawaited(saves.clear());
  }

  /// Kayıtlı oyunu yükler. Kayıt yoksa ya da bozuksa `false` döner ve
  /// çağıran taraf yeni oyun başlatır.
  bool resumeSaved() {
    final state = saves.save;
    if (state == null || !board.restore(state)) {
      return false;
    }
    _boardComponent.clearTiles();
    _boardComponent.buildFromBoard();
    _usedContinue = false;
    beatRecord.value = false;
    isOver.value = false;
    _clearHint();
    _publish();
    return true;
  }

  /// Boş bir hücreye dokunuldu.
  void tapCell(int row, int col) {
    if (isOver.value) {
      return;
    }
    final spawned = board.nextLevel;
    final result = board.place(row, col);
    if (result == null) {
      return;
    }
    audio.place();
    _boardComponent.spawnTile(row, col, spawned);
    _boardComponent.applyResult(result);
    _celebrate(result);
    _afterMove();
  }

  /// Sürükleme bitti: [fromRow], [fromCol] hücresindeki obje hedefe bırakıldı.
  ///
  /// Hamle geçersizse `false` döner ve çağıran obje eski yerine geri gider.
  bool dropTile(int fromRow, int fromCol, int toRow, int toCol) {
    if (isOver.value) {
      return false;
    }
    final result = board.moveTile(fromRow, fromCol, toRow, toCol);
    if (result == null) {
      audio.invalid();
      return false;
    }
    audio.drop();
    _boardComponent.moveTile(fromRow, fromCol, toRow, toCol);
    _boardComponent.applyResult(result);
    _celebrate(result);
    _afterMove();
    return true;
  }

  /// Reklam izlendi: en düşük seviyeden birkaç obje silinip oyun sürüyor.
  void continueAfterAd() {
    if (!canContinue) {
      return;
    }
    _usedContinue = true;
    final removed = board.clearLowest();
    _boardComponent.removeCells(removed);
    isOver.value = false;
    _clearHint();
    _publish();
    unawaited(saves.write(board.toJson()));
  }

  /// Birleşme sonrası ses ve tebrik.
  ///
  /// Ses seviyeyle tizleşiyor; belirli bir seviyeden sonra ayrıca ekranda
  /// kutlama yazısı çıkıyor. Zincir kurulduğunda ayrı bir mesaj veriliyor.
  void _celebrate(MergeResult result) {
    if (!result.didMerge) {
      return;
    }
    final level = result.finalLevel;
    if (level == null) {
      return;
    }

    audio.merge(level);

    // Zincir kendi başına dikkat çekici; ayrı sesi ve mesajı var.
    if (result.chain >= 2) {
      audio.chain();
      _showPopup(
        chainPraiseText(result.chain),
        result.row,
        result.col,
        const Color(0xFFFFD54F),
        size: 26,
      );
      return;
    }

    final praise = mergePraiseText(level);
    if (praise == null) {
      return;
    }
    // Seviye yükseldikçe kutlama da büyüyor.
    if (level >= 9) {
      audio.fanfare();
    } else {
      audio.praise();
    }
    _showPopup(
      praise,
      result.row,
      result.col,
      LevelStyle.colorOf(level),
      size: level >= 9 ? 34 : 28,
    );
  }

  void _showPopup(
    String text,
    int row,
    int col,
    Color colour, {
    required double size,
  }) {
    final centre = centreOf(row, col);
    world.add(
      PopupText(
        text: text,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: colour,
          shadows: const [Shadow(blurRadius: 12, color: Colors.black87)],
        ),
        // Tahtanın üstünde, objeyi kapatmayacak kadar yukarıda.
        position: Vector2(worldWidth / 2, centre.y - cellSide * 0.9),
        popIn: true,
      ),
    );
  }

  void _afterMove() {
    _clearHint();
    _publish();
    if (board.isOver) {
      _finish();
    } else {
      unawaited(saves.write(board.toJson()));
    }
  }

  void _clearHint() {
    _idleSeconds = 0;
    activeHint = null;
    hintPhase = 0;
  }

  void _finish() {
    isOver.value = true;
    audio.gameOver();
    // Biten oyunun kaydı kalmasın; menüde "devam et" çıkmamalı.
    unawaited(saves.clear());
    unawaited(
      highScores.submit(board.score).then((beaten) {
        beatRecord.value = beaten;
      }),
    );
  }

  void _publish() {
    score.value = board.score;
    highestLevel.value = board.highestLevel;
    nextLevel.value = board.nextLevel;
  }

  @override
  void onRemove() {
    score.dispose();
    highestLevel.dispose();
    nextLevel.dispose();
    isOver.dispose();
    beatRecord.dispose();
    super.onRemove();
  }
}

/// Tahtanın zeminini çizen ve dokunuş/sürüklemeyi karşılayan bileşen.
class BoardComponent extends PositionComponent
    with HasGameReference<MergeGame>, TapCallbacks, DragCallbacks {
  /// Hücre indeksi -> o hücredeki obje.
  final Map<int, TileComponent> _tiles = {};

  /// Sürüklenen obje ve nereden alındığı.
  TileComponent? _dragged;
  int _dragFromRow = 0;
  int _dragFromCol = 0;

  static final Paint _cellPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.045);
  static final Paint _framePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = Colors.white.withValues(alpha: 0.07);

  /// İpucu halkası; rengi ve kalınlığı her karede değiştiği için nesne
  /// yeniden üretilmiyor, üzerine yazılıyor.
  final Paint _hintPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round;

  int _index(int row, int col) => row * game.board.size + col;

  @override
  Future<void> onLoad() async {
    layout();
  }

  /// Ekran ölçüsü değişince tahtayı ve objeleri yeniden yerleştirir.
  void layout() {
    position = Vector2.zero();
    size = Vector2(MergeGame.worldWidth, game.worldHeight);
    for (final tile in _tiles.values) {
      tile.size = Vector2.all(game.cellSide);
      tile.position = game.centreOf(tile.row, tile.col);
    }
  }

  void clearTiles() {
    for (final tile in _tiles.values) {
      tile.removeFromParent();
    }
    _tiles.clear();
  }

  /// Kayıttan gelen tahtayı ekrana kurar.
  void buildFromBoard() {
    for (var row = 0; row < game.board.size; row++) {
      for (var col = 0; col < game.board.size; col++) {
        final level = game.board.levelAt(row, col);
        if (level == null) {
          continue;
        }
        final tile = TileComponent(
          level: level,
          row: row,
          col: col,
          position: game.centreOf(row, col),
          side: game.cellSide,
        );
        _tiles[_index(row, col)] = tile;
        add(tile);
      }
    }
  }

  /// Devam etme sırasında silinen hücreleri ekrandan kaldırır.
  void removeCells(List<int> indices) {
    for (final index in indices) {
      final tile = _tiles.remove(index);
      if (tile == null) {
        continue;
      }
      tile.add(
        ScaleEffect.to(
          Vector2.zero(),
          EffectController(duration: 0.2, curve: Curves.easeIn),
          onComplete: tile.removeFromParent,
        ),
      );
    }
  }

  /// Yeni obje: küçükten büyüyerek beliriyor.
  void spawnTile(int row, int col, int level) {
    final tile = TileComponent(
      level: level,
      row: row,
      col: col,
      position: game.centreOf(row, col),
      side: game.cellSide,
    )..scale = Vector2.all(0.4);
    _tiles[_index(row, col)] = tile;
    add(tile);
    tile.add(
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(duration: 0.18, curve: Curves.easeOutBack),
      ),
    );
  }

  /// Var olan objenin hücresini değiştirir ve yeni yerine kaydırır.
  void moveTile(int fromRow, int fromCol, int toRow, int toCol) {
    final tile = _tiles.remove(_index(fromRow, fromCol));
    if (tile == null) {
      return;
    }
    tile
      ..row = toRow
      ..col = toCol;
    _tiles[_index(toRow, toCol)] = tile;
    tile.add(
      MoveToEffect(
        game.centreOf(toRow, toCol),
        EffectController(duration: 0.12, curve: Curves.easeOut),
      ),
    );
  }

  /// Modelin verdiği sonucu ekrana uygular: birleşenler siliniyor, kalan
  /// objenin seviyesi yükseliyor.
  void applyResult(MergeResult result) {
    if (!result.didMerge) {
      return;
    }
    final survivor = _index(result.row, result.col);
    for (final index in result.mergedCells) {
      if (index == survivor) {
        continue;
      }
      final tile = _tiles.remove(index);
      if (tile == null) {
        continue;
      }
      // Birleşen objeler kazananın üstüne doğru büzülerek kayboluyor.
      tile.add(
        MoveToEffect(
          game.centreOf(result.row, result.col),
          EffectController(duration: 0.14, curve: Curves.easeIn),
        ),
      );
      tile.add(
        ScaleEffect.to(
          Vector2.zero(),
          EffectController(duration: 0.14),
          onComplete: tile.removeFromParent,
        ),
      );
    }

    final level = result.finalLevel;
    final tile = _tiles[survivor];
    if (tile != null && level != null) {
      tile.level = level;
      tile.priority = 1;
      tile.add(
        SequenceEffect([
          ScaleEffect.to(
            Vector2.all(1.22),
            EffectController(duration: 0.1, curve: Curves.easeOut),
          ),
          ScaleEffect.to(
            Vector2.all(1),
            EffectController(duration: 0.14, curve: Curves.easeIn),
          ),
        ], onComplete: () => tile.priority = 0),
      );
    }
  }

  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  void onTapUp(TapUpEvent event) {
    final cell = game.cellAt(event.localPosition);
    if (cell == null) {
      return;
    }
    game.tapCell(cell.$1, cell.$2);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    final cell = game.cellAt(event.localPosition);
    if (cell == null) {
      return;
    }
    final tile = _tiles[_index(cell.$1, cell.$2)];
    if (tile == null) {
      return;
    }
    _dragged = tile;
    _dragFromRow = cell.$1;
    _dragFromCol = cell.$2;
    // Sürüklenen obje diğerlerinin üstünde ve biraz büyük dursun.
    tile.priority = 10;
    tile.add(
      ScaleEffect.to(Vector2.all(1.12), EffectController(duration: 0.1)),
    );
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    _dragged?.position += event.localDelta;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _finishDrag();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _finishDrag();
  }

  void _finishDrag() {
    final tile = _dragged;
    if (tile == null) {
      return;
    }
    _dragged = null;
    tile.priority = 0;
    tile.add(ScaleEffect.to(Vector2.all(1), EffectController(duration: 0.1)));

    final target = game.cellAt(tile.position);
    final moved =
        target != null &&
        game.dropTile(_dragFromRow, _dragFromCol, target.$1, target.$2);
    if (!moved) {
      // Geçersiz hamle: obje bulunduğu hücreye geri kayıyor.
      tile.add(
        MoveToEffect(
          game.centreOf(tile.row, tile.col),
          EffectController(duration: 0.14, curve: Curves.easeOut),
        ),
      );
    }
  }

  @override
  void render(Canvas canvas) {
    final origin = game.boardOrigin;
    final side = game.cellSide;
    final step = side + MergeGame._gap;
    final radius = Radius.circular(side * 0.18);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          origin.x - 6,
          origin.y - 6,
          game.boardSide + 12,
          game.boardSide + 12,
        ),
        Radius.circular(side * 0.24),
      ),
      _framePaint,
    );

    for (var row = 0; row < game.board.size; row++) {
      for (var col = 0; col < game.board.size; col++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              origin.x + col * step,
              origin.y + row * step,
              side,
              side,
            ),
            radius,
          ),
          _cellPaint,
        );
      }
    }

    _renderHint(canvas, origin, side, step, radius);
  }

  /// Boşta kalınca önerilen hamlenin hücreleri nefes alır gibi parlıyor.
  void _renderHint(
    Canvas canvas,
    Vector2 origin,
    double side,
    double step,
    Radius radius,
  ) {
    final hint = game.activeHint;
    if (hint == null) {
      return;
    }
    // 0..1 arası yumuşak gidip gelme.
    final beat = (sin(game.hintPhase) + 1) / 2;
    // Sarı "şunu şuraya sürükle", mavi "buraya dokun" demek.
    final colour = hint.isTap
        ? const Color(0xFF7FDBFF)
        : const Color(0xFFFFD54F);

    _hintPaint
      ..strokeWidth = side * (0.045 + beat * 0.05)
      ..color = colour.withValues(alpha: 0.35 + beat * 0.55);

    for (final cell in hint.cells) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            origin.x + cell.$2 * step,
            origin.y + cell.$1 * step,
            side,
            side,
          ).deflate(side * 0.03),
          radius,
        ),
        _hintPaint,
      );
    }
  }
}

/// Sıradaki objenin küçük önizlemesi — HUD'da ve oyun sonu kartında.
class NextTilePreview extends StatelessWidget {
  const NextTilePreview({required this.level, super.key});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: LevelStyle.colorOf(level),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        '$level',
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}
