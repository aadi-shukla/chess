import 'package:chess/chess_engine/chess_engine.dart';
import 'package:chess/features/game/domain/entities/game_mode.dart';
import 'package:chess/features/game/domain/entities/saved_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Offline game logic', () {
    test('local PvP game accepts legal opening moves', () {
      final game = ChessGame();
      expect(game.makeMoveFromUci('e2e4'), isTrue);
      expect(game.makeMoveFromUci('e7e5'), isTrue);
      expect(game.moves, hasLength(2));
    });

    test('illegal move returns false', () {
      final game = ChessGame();
      expect(game.makeMoveFromUci('e2e5'), isFalse);
      expect(game.moves, isEmpty);
    });

    test('undo restores previous position', () {
      final game = ChessGame();
      game.makeMoveFromUci('e2e4');
      game.makeMoveFromUci('e7e5');
      expect(game.canUndo, isTrue);
      game.undo();
      expect(game.canUndo, isTrue);
      expect(
        game.position.pieceAt(Square.fromAlgebraic('e5')!),
        isNull,
      );
    });

    test('saved game round-trips through persistence', () {
      final game = ChessGame();
      game.makeMoveFromUci('d2d4');
      game.makeMoveFromUci('d7d5');

      final saved = SavedGame(
        id: 'local-1',
        mode: GameMode.playerVsPlayer,
        snapshot: ChessGamePersistence.capture(game),
        savedAt: DateTime.now(),
        aiDifficulty: AiDifficulty.medium,
        humanColor: ChessColor.white,
        moveCount: 2,
      );

      final restored = ChessGamePersistence.restore(saved.snapshot);
      expect(restored.moves, hasLength(2));
      expect(restored.position.pieceAt(Square.fromAlgebraic('d4')!), isNotNull);
    });
  });
}
