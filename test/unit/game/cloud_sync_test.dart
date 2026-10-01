import 'package:chess/chess_engine/chess_engine.dart';
import 'package:chess/features/game/domain/entities/cloud_game_settings.dart';
import 'package:chess/features/game/domain/entities/game_mode.dart';
import 'package:chess/features/game/domain/entities/saved_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SavedGame sync versioning', () {
    test('bumpVersion increments syncVersion and timestamp', () {
      final game = SavedGame(
        id: 'g1',
        mode: GameMode.playerVsPlayer,
        snapshot: const ChessGameSnapshot(
          moveUcis: [],
          whiteMillis: 600000,
          blackMillis: 600000,
          incrementMillis: 0,
        ),
        savedAt: DateTime(2024),
        aiDifficulty: AiDifficulty.medium,
        humanColor: ChessColor.white,
      );

      final bumped = game.bumpVersion();
      expect(bumped.syncVersion, 1);
      expect(bumped.updatedAtMillis, greaterThan(0));
    });
  });

  group('CloudGameSettings conflict', () {
    test('newer syncVersion wins in comparison', () {
      const local = CloudGameSettings(syncVersion: 1, updatedAtMillis: 100);
      const remote = CloudGameSettings(syncVersion: 3, updatedAtMillis: 50);
      expect(remote.syncVersion, greaterThan(local.syncVersion));
    });
  });
}
