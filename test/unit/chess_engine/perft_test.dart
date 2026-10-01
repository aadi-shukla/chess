import 'package:chess/chess_engine/chess_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('perft', () {
    test('starting position depth 1-4', () {
      final position = FenParser.fromFen(FenParser.startingFen);
      expect(perft(position, 1), 20);
      expect(perft(position, 2), 400);
      expect(perft(position, 3), 8902);
      expect(perft(position, 4), 197281);
    });

    test('kiwipete position depth 1-3', () {
      final position = FenParser.fromFen(
        'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1',
      );
      expect(perft(position, 1), 48);
      expect(perft(position, 2), 2039);
      expect(perft(position, 3), 97862);
    });

    test('position 3 en passant depth 1-4', () {
      final position = FenParser.fromFen(
        '8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1',
      );
      expect(perft(position, 1), 14);
      expect(perft(position, 2), 191);
      expect(perft(position, 3), 2812);
      expect(perft(position, 4), 43238);
    });

    test('position 4 promotions depth 1-4', () {
      final position = FenParser.fromFen(
        'r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1',
      );
      expect(perft(position, 1), 6);
      expect(perft(position, 2), 264);
      expect(perft(position, 3), 9467);
      expect(perft(position, 4), 422333);
    });
  });

  group('FEN', () {
    test('round-trip starting position', () {
      const fen = FenParser.startingFen;
      final position = FenParser.fromFen(fen);
      expect(FenParser.toFen(position), fen);
    });
  });

  group('special moves', () {
    test('white can castle kingside', () {
      final position = FenParser.fromFen(
        'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1',
      );
      final moves = MoveGenerator.generateLegalMoves(position);
      expect(
        moves.any((m) => m.isCastle && m.to == Square.g1),
        isTrue,
      );
    });

    test('en passant capture is legal', () {
      final position = FenParser.fromFen(
        'rnbqkbnr/ppp2ppp/8/3pP3/8/8/PPP1PPPP/RNBQKBNR w KQkq d6 0 3',
      );
      final moves = MoveGenerator.generateLegalMoves(position);
      expect(
        moves.any((m) => m.isEnPassant && m.to == Square.d6),
        isTrue,
      );
    });

    test('pawn promotion generates four options', () {
      final position = FenParser.fromFen(
        '8/P7/8/8/8/8/8/4K2k w - - 0 1',
      );
      final moves = MoveGenerator.generateLegalMoves(position);
      final promotions = moves.where((m) => m.to == Square.a8).toList();
      expect(promotions.length, 4);
    });

    test('en passant pinned king move is rejected', () {
      final position = FenParser.fromFen(
        'rnbqkbnr/ppp2ppp/8/3pP3/8/8/PPP1PPPP/RNBQKBNR w KQkq d6 0 3',
      );
      final epMoves = MoveGenerator.generateLegalMoves(position)
          .where((m) => m.isEnPassant)
          .toList();
      for (final move in epMoves) {
        final next = MoveExecutor.apply(position, move);
        expect(
          AttackDetector.isInCheck(next, ChessColor.white),
          isFalse,
        );
      }
    });
  });

  group('game status', () {
    test('detects checkmate - fools mate', () {
      final game = ChessGame();
      game.makeMoveFromUci('f2f3');
      game.makeMoveFromUci('e7e5');
      game.makeMoveFromUci('g2g4');
      game.makeMoveFromUci('d8h4');

      expect(game.status.outcome, GameOutcome.checkmate);
    });

    test('detects stalemate', () {
      final position = FenParser.fromFen(
        '7k/5Q2/6K1/8/8/8/8/8 b - - 0 1',
      );
      final status = GameStatus.analyze(position, repetitionCounts: {});
      expect(status.outcome, GameOutcome.stalemate);
    });

    test('detects fifty-move draw', () {
      final position = FenParser.fromFen(
        'K7/8/8/8/8/8/8/k7 w - - 100 150',
      );
      final status = GameStatus.analyze(position, repetitionCounts: {});
      expect(status.outcome, GameOutcome.drawFiftyMove);
    });
  });

  group('undo redo', () {
    test('undo restores position', () {
      final game = ChessGame();
      final fenBefore = game.fen;
      game.makeMoveFromUci('e2e4');
      expect(game.canUndo, isTrue);
      game.undo();
      expect(game.fen, fenBefore);
      expect(game.canRedo, isTrue);
      game.redo();
      expect(game.moves.length, 1);
    });
  });

  group('PGN export', () {
    test('exports moves', () {
      final game = ChessGame();
      game.makeMoveFromUci('e2e4');
      game.makeMoveFromUci('e7e5');
      final pgn = game.exportPgn();
      expect(pgn, contains('1. e4 e5'));
    });
  });

  group('chess clock', () {
    test('tracks millis per side', () {
      final clock = ChessClock(whiteMillis: 60000, blackMillis: 60000);
      clock.start(ChessColor.white);
      expect(clock.millisFor(ChessColor.white), 60000);
      clock.switchTurn(ChessColor.black);
      expect(clock.activeColor, ChessColor.black);
    });
  });
}
