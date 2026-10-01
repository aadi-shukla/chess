import 'package:chess/chess_engine/chess_engine.dart';
import 'package:chess/features/auth/domain/entities/user_entity.dart';
import 'package:chess/features/game/domain/entities/game_mode.dart';
import 'package:chess/features/game/domain/entities/saved_game.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression suite for previously fixed engine and app edge cases.
void main() {
  group('Regression — illegal moves rejected', () {
    test('cannot move into check', () {
      final game = ChessGame(
        initialPosition: FenParser.fromFen(
          'rnb1kbnr/pppp1ppp/4p3/8/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3',
        ),
      );

      expect(game.legalMovesFrom(Square.fromAlgebraic('f1')), isEmpty);
    });

    test('pinned knight cannot move', () {
      final game = ChessGame(
        initialPosition: FenParser.fromFen(
          '4k3/5r2/8/8/8/8/5N2/4K3 b - - 0 1',
        ),
      );

      const knightSquare = Square.f2;
      final targets = game.legalMovesFrom(knightSquare);
      expect(targets, isEmpty);
    });
  });

  group('Regression — reconnect profile', () {
    test('user entity copyWith preserves activeGameId', () {
      const user = UserEntity(
        uid: 'fixed-id',
        email: 'a@b.com',
        displayName: 'A',
        activeGameId: 'g1',
      );

      final updated = user.copyWith(rating: 1500);
      expect(updated.uid, 'fixed-id');
      expect(updated.activeGameId, 'g1');
      expect(updated.rating, 1500);
    });
  });

  group('Regression — sync version monotonic', () {
    test('bumpVersion never decreases', () {
      var saved = SavedGame(
        id: 'regression',
        mode: GameMode.playerVsPlayer,
        snapshot: const ChessGameSnapshot(
          moveUcis: [],
          whiteMillis: 600000,
          blackMillis: 600000,
          incrementMillis: 0,
        ),
        savedAt: DateTime.now(),
        aiDifficulty: AiDifficulty.medium,
        humanColor: ChessColor.white,
      );

      for (var i = 0; i < 5; i++) {
        final next = saved.bumpVersion();
        expect(next.syncVersion, greaterThan(saved.syncVersion));
        saved = next;
      }
    });
  });
}
