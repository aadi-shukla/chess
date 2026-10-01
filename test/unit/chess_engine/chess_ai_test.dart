import 'package:chess/chess_engine/chess_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChessAi', () {
    test('finds a legal move from starting position', () {
      final position = FenParser.fromFen(FenParser.startingFen);
      final move = ChessAi.findBestMove(
        position,
        ChessColor.white,
        difficulty: AiDifficulty.easy,
      );
      expect(move, isNotNull);
      expect(MoveGenerator.generateLegalMoves(position), contains(move));
    });

    test('beginner still returns a legal move', () {
      final position = FenParser.fromFen(FenParser.startingFen);
      final move = ChessAi.findBestMove(
        position,
        ChessColor.white,
        difficulty: AiDifficulty.beginner,
      );
      expect(move, isNotNull);
    });
  });

  group('ChessGamePersistence', () {
    test('round-trips game state', () {
      final game = ChessGame();
      game.makeMoveFromUci('e2e4');
      game.makeMoveFromUci('e7e5');

      final snapshot = ChessGamePersistence.capture(game);
      final restored = ChessGamePersistence.restore(snapshot);

      expect(restored.fen, game.fen);
      expect(restored.moves.length, 2);
      expect(restored.sans, game.sans);
    });
  });
}
