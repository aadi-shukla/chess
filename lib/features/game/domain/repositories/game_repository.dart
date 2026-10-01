import 'package:chess/chess_engine/chess_engine.dart';
import 'package:chess/core/errors/result.dart';
import 'package:chess/features/game/domain/entities/board_theme.dart';
import 'package:chess/features/game/domain/entities/game_history_entry.dart';
import 'package:chess/features/game/domain/entities/game_statistics.dart';
import 'package:chess/features/game/domain/entities/saved_game.dart';
import 'package:chess/features/game/domain/entities/sync_state.dart';

/// Offline game persistence, statistics, and cloud sync.
abstract class GameRepository {
  bool get cloudSyncAvailable;

  Stream<SyncState> get syncState;

  Future<SavedGame?> loadSavedGame();
  Future<void> saveGame(SavedGame game);
  Future<void> clearSavedGame();
  Future<GameStatistics> loadStatistics();
  Future<void> saveStatistics(GameStatistics stats);
  Future<List<GameHistoryEntry>> loadHistory();
  Future<void> recordHistory(GameHistoryEntry entry);
  Future<BoardTheme> loadBoardTheme();
  Future<void> saveBoardTheme(BoardTheme theme);
  Future<int> loadDefaultMinutes();
  Future<void> saveDefaultMinutes(int minutes);
  Future<int> loadDefaultIncrement();
  Future<void> saveDefaultIncrement(int seconds);
  Future<AiDifficulty> loadDefaultAiDifficulty();
  Future<void> saveDefaultAiDifficulty(AiDifficulty difficulty);
  Future<bool> loadHapticsEnabled();
  Future<void> saveHapticsEnabled(bool enabled);
  Future<bool> loadAutoSaveEnabled();
  Future<void> saveAutoSaveEnabled(bool enabled);

  /// Sets the authenticated user id for cloud sync operations.
  void setSyncUid(String? uid);

  /// Pulls remote data and pushes local changes for [uid].
  Future<Result<void>> syncToCloud(String uid);

  /// Flushes pending offline sync queue.
  Future<Result<void>> flushPendingSync(String uid);
}
