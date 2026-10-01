import 'package:chess/chess_engine/chess_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Performance — chess engine', () {
    test('perft depth 4 completes within budget', () {
      final position = FenParser.fromFen(FenParser.startingFen);
      final stopwatch = Stopwatch()..start();
      final nodes = perft(position, 4);
      stopwatch.stop();

      expect(nodes, 197281);
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(8000),
        reason: 'Perft(4) should finish in under 8s on CI hardware',
      );
    });

    test('legal move generation scales linearly at depth 1', () {
      final game = ChessGame();
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 1000; i++) {
        for (var sq = 0; sq < 64; sq++) {
          final square = Square.fromIndex(sq);
          if (square != null) {
            game.legalMovesFrom(square);
          }
        }
      }

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
    });
  });
}
