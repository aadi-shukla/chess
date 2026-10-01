import 'package:chess/chess_engine/chess_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Chess rules — comprehensive', () {
    test('castling rights lost after king move', () {
      final game = ChessGame();
      game.makeMoveFromUci('e2e4');
      game.makeMoveFromUci('e7e5');
      game.makeMoveFromUci('e1e2');
      game.makeMoveFromUci('g8f6');

      expect(game.position.castlingRights.whiteKingSide, isFalse);
      expect(game.position.castlingRights.whiteQueenSide, isFalse);
    });

    test('en passant capture is legal only immediately', () {
      final game = ChessGame(
        initialPosition: FenParser.fromFen(
          'rnbqkbnr/ppp2ppp/4p3/3pP3/8/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 3',
        ),
      );

      final targets = game.legalMovesFrom(Square.fromAlgebraic('e5'));
      expect(
        targets.any((m) => m.to.algebraic == 'd6'),
        isTrue,
      );
    });

    test('promotion moves reach the back rank', () {
      final game = ChessGame(
        initialPosition: FenParser.fromFen(
          '8/P7/8/8/8/8/8/4K2k w - - 0 1',
        ),
      );

      final moves = game.legalMovesFrom(Square.fromAlgebraic('a7'));
      expect(moves, isNotEmpty);
      expect(moves.first.to.rank, 7);
    });

    test('stalemate is detected', () {
      final game = ChessGame(
        initialPosition: FenParser.fromFen(
          '7k/5Q2/6K1/8/8/8/8/8 b - - 0 1',
        ),
      );

      expect(game.status.outcome, GameOutcome.stalemate);
      expect(game.status.isGameOver, isTrue);
    });

    test('insufficient material draw', () {
      final game = ChessGame(
        initialPosition: FenParser.fromFen(
          '8/8/8/8/8/8/4k3/4K2b w - - 0 1',
        ),
      );

      expect(game.status.isDraw, isTrue);
    });
  });
}
