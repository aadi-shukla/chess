import 'package:chess/chess_engine/chess_engine.dart';

void main() {
  const fen = '8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1';
  final position = FenParser.fromFen(fen);
  final moves = MoveGenerator.generateLegalMoves(position);
  // ignore: avoid_print
  print('${moves.length} moves:');
  for (final m in moves) {
    // ignore: avoid_print
    print('  ${m.uci} cap=${m.isCapture} ep=${m.isEnPassant} promo=${m.promotion}');
  }
}
