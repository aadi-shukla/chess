import 'package:chess/chess_engine/src/piece.dart';

/// Chess clock with increment support (pure Dart, no Flutter).
class ChessClock {
  ChessClock({
    this.whiteMillis = 600000,
    this.blackMillis = 600000,
    this.incrementMillis = 0,
    ChessColor? activeColor,
  }) : activeColor = activeColor ?? ChessColor.white;

  int whiteMillis;
  int blackMillis;
  final int incrementMillis;
  ChessColor? activeColor;

  DateTime? _lastTick;

  void start(ChessColor color) {
    activeColor = color;
    _lastTick = DateTime.now();
  }

  void stop() {
    _tick();
    activeColor = null;
    _lastTick = null;
  }

  void switchTurn(ChessColor nextColor) {
    _tick();
    if (incrementMillis > 0 && activeColor != null) {
      _addIncrement(activeColor!);
    }
    activeColor = nextColor;
    _lastTick = DateTime.now();
  }

  void _tick() {
    if (_lastTick == null || activeColor == null) return;
    final elapsed = DateTime.now().difference(_lastTick!).inMilliseconds;
    if (activeColor == ChessColor.white) {
      whiteMillis = (whiteMillis - elapsed).clamp(0, 1 << 31);
    } else {
      blackMillis = (blackMillis - elapsed).clamp(0, 1 << 31);
    }
    _lastTick = DateTime.now();
  }

  void _addIncrement(ChessColor color) {
    if (color == ChessColor.white) {
      whiteMillis += incrementMillis;
    } else {
      blackMillis += incrementMillis;
    }
  }

  int millisFor(ChessColor color) {
    _tick();
    return color == ChessColor.white ? whiteMillis : blackMillis;
  }

  bool get isExpired {
    _tick();
    return whiteMillis <= 0 || blackMillis <= 0;
  }

  ChessColor? get expiredColor {
    _tick();
    if (whiteMillis <= 0) return ChessColor.white;
    if (blackMillis <= 0) return ChessColor.black;
    return null;
  }

  ChessClock copy() {
    return ChessClock(
      whiteMillis: whiteMillis,
      blackMillis: blackMillis,
      incrementMillis: incrementMillis,
      activeColor: activeColor,
    );
  }
}
