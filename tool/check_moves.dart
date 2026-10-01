import 'package:chess/chess_engine/chess_engine.dart';

void main() {
  final pos = FenParser.fromFen(
    '8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1',
  );
  for (final move in MoveGenerator.generatePseudoLegalMoves(pos)) {
    final next = MoveExecutor.apply(pos, move);
    final inCheck = AttackDetector.isInCheck(next, ChessColor.white);
    // ignore: avoid_print
    print('${move.uci} inCheck=$inCheck');
  }
}
