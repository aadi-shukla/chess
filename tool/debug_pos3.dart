import 'package:chess/chess_engine/chess_engine.dart';

void main() {
  final pos = FenParser.fromFen(
    '8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1',
  );
  const king = Square.a5;
  // ignore: avoid_print
  print('h5 attacks a5: ${AttackDetector.isSquareAttacked(pos, king, ChessColor.black)}');
  // ignore: avoid_print
  print('piece b5: ${pos.pieceAt(Square.b5)}');

  final afterKb6 = MoveExecutor.apply(
    pos,
    const ChessMove(from: Square.a5, to: Square.b6),
  );
  // ignore: avoid_print
  print('after Kb6 in check: ${AttackDetector.isInCheck(afterKb6, ChessColor.white)}');

  final afterRxf4 = MoveExecutor.apply(
    pos,
    const ChessMove(from: Square.b4, to: Square.f4, isCapture: true),
  );
  // ignore: avoid_print
  print('after Rxf4 in check: ${AttackDetector.isInCheck(afterRxf4, ChessColor.white)}');
}
