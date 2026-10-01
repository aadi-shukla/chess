import 'package:chess/chess_engine/chess_engine.dart';
import 'package:chess/features/game/data/datasources/game_local_datasource.dart';
import 'package:chess/features/game/data/repositories/game_repository_impl.dart';
import 'package:chess/features/game/domain/entities/board_theme.dart';
import 'package:chess/features/game/domain/entities/game_mode.dart';
import 'package:chess/features/game/domain/entities/game_statistics.dart';
import 'package:chess/features/game/domain/entities/saved_game.dart';
import 'package:chess/features/game/domain/repositories/game_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_harness.dart';

void main() {
  late GameRepository repository;
  late String hivePath;

  setUp(() async {
    hivePath = TestHarness.uniqueHivePath('game_repo');
    await TestHarness.initHive(path: hivePath);
    repository = GameRepositoryImpl(local: GameLocalDataSource());
  });

  tearDown(() async => TestHarness.clearHiveBoxes());

  test('saves and loads statistics', () async {
    const stats = GameStatistics(pvpGames: 5, pvAiWins: 2);
    await repository.saveStatistics(stats);
    final loaded = await repository.loadStatistics();
    expect(loaded.pvpGames, 5);
    expect(loaded.pvAiWins, 2);
  });

  test('saves and clears game', () async {
    final game = ChessGame();
    game.makeMoveFromUci('e2e4');
    final saved = SavedGame(
      id: 'test-id',
      mode: GameMode.playerVsPlayer,
      snapshot: ChessGamePersistence.capture(game),
      savedAt: DateTime.now(),
      aiDifficulty: AiDifficulty.medium,
      humanColor: ChessColor.white,
      moveCount: 1,
    );

    await repository.saveGame(saved);
    final loaded = await repository.loadSavedGame();
    expect(loaded?.id, 'test-id');
    expect(loaded?.moveCount, 1);

    await repository.clearSavedGame();
    expect(await repository.loadSavedGame(), isNull);
  });

  test('persists board theme preference', () async {
    await repository.saveBoardTheme(BoardTheme.ocean);
    expect(await repository.loadBoardTheme(), BoardTheme.ocean);
  });
}
