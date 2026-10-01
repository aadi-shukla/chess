import 'package:chess/chess_engine/chess_engine.dart';
import 'package:chess/core/constants/app_constants.dart';
import 'package:chess/core/errors/result.dart';
import 'package:chess/features/game/data/datasources/game_local_datasource.dart';
import 'package:chess/features/game/data/services/cloud_sync_service.dart';
import 'package:chess/features/game/domain/entities/board_theme.dart';
import 'package:chess/features/game/domain/entities/cloud_game_settings.dart';
import 'package:chess/features/game/domain/entities/game_history_entry.dart';
import 'package:chess/features/game/domain/entities/game_statistics.dart';
import 'package:chess/features/game/domain/entities/saved_game.dart';
import 'package:chess/features/game/domain/entities/sync_state.dart';
import 'package:chess/features/game/domain/failures/sync_failure.dart';
import 'package:chess/features/game/domain/repositories/game_repository.dart';

/// Local-first [GameRepository] with optional cloud sync.
class GameRepositoryImpl implements GameRepository {
  GameRepositoryImpl({
    required GameLocalDataSource local,
    CloudSyncService? cloudSync,
  })  : _local = local,
        _cloudSync = cloudSync;

  final GameLocalDataSource _local;
  final CloudSyncService? _cloudSync;

  @override
  bool get cloudSyncAvailable => _cloudSync != null;

  @override
  Stream<SyncState> get syncState =>
      _cloudSync?.syncState ?? const Stream.empty();

  @override
  Future<void> clearSavedGame() async {
    final existing = await _local.readSavedGame();
    await _local.deleteSavedGame();
    final uid = _pendingUid;
    if (existing != null && uid != null && _cloudSync != null) {
      await _cloudSync.queueClearGame(gameId: existing.id, uid: uid);
    }
  }

  @override
  Future<SavedGame?> loadSavedGame() => _local.readSavedGame();

  @override
  Future<void> saveGame(SavedGame game) async {
    final versioned = game.bumpVersion();
    await _local.writeSavedGame(versioned);
    final uid = _pendingUid;
    if (uid != null && _cloudSync != null) {
      await _cloudSync.queueSavedGame(versioned, uid: uid);
    }
  }

  @override
  void setSyncUid(String? uid) => _pendingUid = uid;

  String? _pendingUid;

  @override
  Future<GameStatistics> loadStatistics() => _local.readStatistics();

  @override
  Future<void> saveStatistics(GameStatistics stats) async {
    await _local.writeStatistics(stats);
    await _queueSettingsPush();
  }

  @override
  Future<List<GameHistoryEntry>> loadHistory() => _local.readHistory();

  @override
  Future<void> recordHistory(GameHistoryEntry entry) async {
    final uid = _pendingUid;
    if (uid != null && _cloudSync != null) {
      await _cloudSync.queueHistory(uid: uid, entry: entry);
    } else {
      await _local.appendHistory(entry);
    }
  }

  @override
  Future<BoardTheme> loadBoardTheme() async {
    final name = await _local.readString(AppConstants.boardThemeKey);
    if (name == null) return BoardTheme.classic;
    return BoardTheme.values.byName(name);
  }

  @override
  Future<void> saveBoardTheme(BoardTheme theme) async {
    await _local.writeString(AppConstants.boardThemeKey, theme.name);
    await _queueSettingsPush();
  }

  @override
  Future<int> loadDefaultMinutes() =>
      _local.readInt(AppConstants.defaultMinutesKey, defaultValue: 10);

  @override
  Future<void> saveDefaultMinutes(int minutes) async {
    await _local.writeInt(AppConstants.defaultMinutesKey, minutes);
    await _queueSettingsPush();
  }

  @override
  Future<int> loadDefaultIncrement() =>
      _local.readInt(AppConstants.defaultIncrementKey);

  @override
  Future<void> saveDefaultIncrement(int seconds) async {
    await _local.writeInt(AppConstants.defaultIncrementKey, seconds);
    await _queueSettingsPush();
  }

  @override
  Future<AiDifficulty> loadDefaultAiDifficulty() async {
    final name = await _local.readString(AppConstants.defaultAiDifficultyKey);
    if (name == null) return AiDifficulty.medium;
    return AiDifficulty.values.byName(name);
  }

  @override
  Future<void> saveDefaultAiDifficulty(AiDifficulty difficulty) async {
    await _local.writeString(
      AppConstants.defaultAiDifficultyKey,
      difficulty.name,
    );
    await _queueSettingsPush();
  }

  @override
  Future<bool> loadHapticsEnabled() =>
      _local.readBool(AppConstants.hapticsEnabledKey);

  @override
  Future<void> saveHapticsEnabled(bool enabled) async {
    await _local.writeBool(AppConstants.hapticsEnabledKey, enabled);
    await _queueSettingsPush();
  }

  @override
  Future<bool> loadAutoSaveEnabled() =>
      _local.readBool(AppConstants.autoSaveEnabledKey);

  @override
  Future<void> saveAutoSaveEnabled(bool enabled) async {
    await _local.writeBool(AppConstants.autoSaveEnabledKey, enabled);
    await _queueSettingsPush();
  }

  @override
  Future<Result<void>> syncToCloud(String uid) async {
    setSyncUid(uid);
    if (_cloudSync == null) {
      return const Error(
        SyncFailure('Cloud sync is unavailable.', code: 'unavailable'),
      );
    }
    return _cloudSync.syncAll(uid: uid);
  }

  @override
  Future<Result<void>> flushPendingSync(String uid) async {
    setSyncUid(uid);
    if (_cloudSync == null) {
      return const Error(
        SyncFailure('Cloud sync is unavailable.', code: 'unavailable'),
      );
    }
    try {
      await _cloudSync.flushQueue(uid: uid);
      return const Success(null);
    } on Exception catch (e) {
      return Error(SyncFailure('Flush failed: $e'));
    }
  }

  Future<void> _queueSettingsPush() async {
    final uid = _pendingUid;
    if (uid == null || _cloudSync == null) return;

    final settings = CloudGameSettings(
      boardTheme: await loadBoardTheme(),
      defaultMinutes: await loadDefaultMinutes(),
      defaultIncrement: await loadDefaultIncrement(),
      defaultAiDifficulty: await loadDefaultAiDifficulty(),
      hapticsEnabled: await loadHapticsEnabled(),
      autoSaveEnabled: await loadAutoSaveEnabled(),
      statistics: await loadStatistics(),
    );
    await _cloudSync.queueSettings(uid: uid, settings: settings);
  }
}

/// Hive-only fallback when Firebase is not initialized.
class LocalOnlyGameRepository extends GameRepositoryImpl {
  LocalOnlyGameRepository(GameLocalDataSource local)
      : super(local: local, cloudSync: null);
}
