import 'dart:async';
import 'dart:math';

import 'package:chess/chess_engine/chess_engine.dart';
import 'package:chess/core/constants/app_constants.dart';
import 'package:chess/core/errors/result.dart';
import 'package:chess/core/network/connectivity_service.dart';
import 'package:chess/core/utils/app_logger.dart';
import 'package:chess/features/game/data/datasources/game_local_datasource.dart';
import 'package:chess/features/game/data/datasources/game_remote_datasource.dart';
import 'package:chess/features/game/domain/entities/board_theme.dart';
import 'package:chess/features/game/domain/entities/cloud_game_settings.dart';
import 'package:chess/features/game/domain/entities/game_history_entry.dart';
import 'package:chess/features/game/domain/entities/game_statistics.dart';
import 'package:chess/features/game/domain/entities/saved_game.dart';
import 'package:chess/features/game/domain/entities/sync_queue_entry.dart';
import 'package:chess/features/game/domain/entities/sync_state.dart';
import 'package:chess/features/game/domain/failures/sync_failure.dart';

/// Orchestrates bidirectional cloud sync with offline queue and retries.
class CloudSyncService {
  CloudSyncService({
    required GameLocalDataSource local,
    required GameRemoteDataSource remote,
    required ConnectivityService connectivity,
  })  : _local = local,
        _remote = remote,
        _connectivity = connectivity;

  final GameLocalDataSource _local;
  final GameRemoteDataSource _remote;
  final ConnectivityService _connectivity;

  final _syncState = StreamController<SyncState>.broadcast();
  SyncState _currentState = const SyncState();

  Stream<SyncState> get syncState => _syncState.stream;
  SyncState get currentState => _currentState;

  static const _baseRetryDelayMs = 1000;
  static const _maxRetryDelayMs = 30000;

  void _emit(SyncState state) {
    _currentState = state;
    _syncState.add(state);
  }

  /// Full bidirectional sync for the signed-in user.
  Future<Result<void>> syncAll({required String uid}) async {
    if (!_connectivity.isOnline) {
      _emit(_currentState.copyWith(status: SyncStatus.offline));
      return const Error(SyncFailure.offline());
    }

    _emit(_currentState.copyWith(status: SyncStatus.syncing));

    try {
      await flushQueue(uid: uid);
      await _pullRemote(uid);
      await _pushLocal(uid);
      await _local.writeLastSyncMillis(DateTime.now().millisecondsSinceEpoch);
      final pending = (await _local.readSyncQueue()).length;
      _emit(
        SyncState(
          status: SyncStatus.success,
          lastSyncedAt: DateTime.now(),
          pendingOperations: pending,
        ),
      );
      return const Success(null);
    } on Exception catch (e, st) {
      AppLogger.instance.e('Cloud sync failed', error: e, stackTrace: st);
      _emit(
        _currentState.copyWith(
          status: SyncStatus.error,
          errorMessage: e.toString(),
        ),
      );
      return Error(SyncFailure('Sync failed: $e'));
    }
  }

  Future<void> queueSavedGame(SavedGame game, {required String uid}) async {
    await _local.enqueue(
      SyncQueueEntry(
        id: game.id,
        type: SyncOperationType.savedGame,
        payload: game.toJson(),
        createdAtMillis: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    if (_connectivity.isOnline) {
      await flushQueue(uid: uid);
    }
  }

  Future<void> queueClearGame({
    required String gameId,
    required String uid,
  }) async {
    await _local.deleteSavedGame();
    await _local.enqueue(
      SyncQueueEntry(
        id: gameId,
        type: SyncOperationType.clearGame,
        payload: {'gameId': gameId},
        createdAtMillis: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    if (_connectivity.isOnline) {
      await flushQueue(uid: uid);
    }
  }

  Future<void> queueSettings({
    required String uid,
    required CloudGameSettings settings,
  }) async {
    final versioned = settings.bumpVersion();
    await _local.writeCloudSettingsCache(versioned);
    await _local.enqueue(
      SyncQueueEntry(
        id: 'settings',
        type: SyncOperationType.settings,
        payload: versioned.toJson(),
        createdAtMillis: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    if (_connectivity.isOnline) {
      await flushQueue(uid: uid);
    }
  }

  Future<void> queueHistory({
    required String uid,
    required GameHistoryEntry entry,
  }) async {
    final versioned = entry.bumpVersion();
    await _local.appendHistory(versioned);
    await _local.enqueue(
      SyncQueueEntry(
        id: entry.id,
        type: SyncOperationType.history,
        payload: versioned.toJson(),
        createdAtMillis: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    if (_connectivity.isOnline) {
      await flushQueue(uid: uid);
    }
  }

  /// Processes pending queue with exponential backoff retries.
  Future<void> flushQueue({required String uid}) async {
    if (!_connectivity.isOnline) return;

    final queue = await _local.readSyncQueue();
    if (queue.isEmpty) return;

    final remaining = <SyncQueueEntry>[];

    for (final entry in queue) {
      try {
        await _executeEntry(entry, uid: uid);
      } on Exception catch (e) {
        AppLogger.instance.w('Sync queue item failed: ${entry.type}', error: e);
        if (entry.canRetry) {
          remaining.add(entry.withRetry());
          await Future<void>.delayed(
            Duration(milliseconds: _retryDelay(entry.retries + 1)),
          );
        }
      }
    }

    await _local.writeSyncQueue(remaining);
    _emit(
      _currentState.copyWith(
        pendingOperations: remaining.length,
      ),
    );
  }

  int _retryDelay(int attempt) {
    final delay = _baseRetryDelayMs * pow(2, attempt).toInt();
    return delay.clamp(_baseRetryDelayMs, _maxRetryDelayMs);
  }

  Future<void> _executeEntry(SyncQueueEntry entry, {required String uid}) async {
    switch (entry.type) {
      case SyncOperationType.savedGame:
        final game = SavedGame.fromJson(entry.payload);
        await _remote.upsertSavedGame(uid: uid, game: game);
      case SyncOperationType.clearGame:
        final gameId = entry.payload['gameId'] as String;
        await _remote.deleteSavedGame(uid: uid, gameId: gameId);
      case SyncOperationType.settings:
        final settings = CloudGameSettings.fromJson(entry.payload);
        await _remote.upsertSettings(uid: uid, settings: settings);
      case SyncOperationType.history:
        final history = GameHistoryEntry.fromJson(entry.payload);
        await _remote.upsertHistoryEntry(uid: uid, entry: history);
    }
  }

  Future<void> _pullRemote(String uid) async {
    final remoteGame = await _remote.fetchActiveSavedGame(uid);
    final localGame = await _local.readSavedGame();

    if (remoteGame != null) {
      final merged = _resolveGameConflict(local: localGame, remote: remoteGame);
      if (merged != null && merged != localGame) {
        await _local.writeSavedGame(merged);
      }
    }

    final remoteSettings = await _remote.fetchSettings(uid);
    if (remoteSettings != null) {
      final localCache = await _local.readCloudSettingsCache();
      final resolved = _resolveSettingsConflict(
        local: localCache,
        remote: remoteSettings,
      );
      // Statistics are cumulative counters, so a straight last-writer-wins on
      // the whole settings object would silently discard games recorded on the
      // other device. Merge them by taking the max of each counter.
      final localStats = await _local.readStatistics();
      final merged = resolved.copyWith(
        statistics: _mergeStatistics(
          local: localStats,
          remote: resolved.statistics,
        ),
      );
      await _applySettingsLocally(merged);
      await _local.writeCloudSettingsCache(merged);
    }

    final remoteHistory = await _remote.fetchHistory(uid);
    if (remoteHistory.isNotEmpty) {
      final localHistory = await _local.readHistory();
      final merged = _mergeHistory(local: localHistory, remote: remoteHistory);
      await _local.writeHistory(merged);
    }
  }

  Future<void> _pushLocal(String uid) async {
    final game = await _local.readSavedGame();
    if (game != null && !game.deleted) {
      await _remote.upsertSavedGame(uid: uid, game: game.bumpVersion());
    }

    final settings = await _buildLocalSettings();
    await _remote.upsertSettings(uid: uid, settings: settings.bumpVersion());

    final history = await _local.readHistory();
    for (final entry in history.take(10)) {
      await _remote.upsertHistoryEntry(uid: uid, entry: entry);
    }
  }

  Future<CloudGameSettings> _buildLocalSettings() async {
    return CloudGameSettings(
      boardTheme: BoardTheme.values.byName(
        await _local.readString(AppConstants.boardThemeKey) ??
            BoardTheme.classic.name,
      ),
      defaultMinutes: await _local.readInt(
        AppConstants.defaultMinutesKey,
        defaultValue: 10,
      ),
      defaultIncrement:
          await _local.readInt(AppConstants.defaultIncrementKey),
      defaultAiDifficulty: AiDifficulty.values.byName(
        await _local.readString(AppConstants.defaultAiDifficultyKey) ??
            AiDifficulty.medium.name,
      ),
      hapticsEnabled:
          await _local.readBool(AppConstants.hapticsEnabledKey),
      autoSaveEnabled:
          await _local.readBool(AppConstants.autoSaveEnabledKey),
      statistics: await _local.readStatistics(),
      updatedAtMillis: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _applySettingsLocally(CloudGameSettings settings) async {
    await _local.writeString(
      AppConstants.boardThemeKey,
      settings.boardTheme.name,
    );
    await _local.writeInt(
      AppConstants.defaultMinutesKey,
      settings.defaultMinutes,
    );
    await _local.writeInt(
      AppConstants.defaultIncrementKey,
      settings.defaultIncrement,
    );
    await _local.writeString(
      AppConstants.defaultAiDifficultyKey,
      settings.defaultAiDifficulty.name,
    );
    await _local.writeBool(
      AppConstants.hapticsEnabledKey,
      settings.hapticsEnabled,
    );
    await _local.writeBool(
      AppConstants.autoSaveEnabledKey,
      settings.autoSaveEnabled,
    );
    await _local.writeStatistics(settings.statistics);
  }

  SavedGame? _resolveGameConflict({
    required SavedGame? local,
    required SavedGame remote,
  }) {
    if (local == null) return remote;
    if (local.id != remote.id) {
      return remote.updatedAtMillis >= local.updatedAtMillis
          ? remote
          : local;
    }
    if (remote.syncVersion > local.syncVersion) return remote;
    if (local.syncVersion > remote.syncVersion) return local;
    return remote.updatedAtMillis >= local.updatedAtMillis
        ? remote
        : local;
  }

  CloudGameSettings _resolveSettingsConflict({
    required CloudGameSettings? local,
    required CloudGameSettings remote,
  }) {
    if (local == null) return remote;
    if (remote.syncVersion > local.syncVersion) return remote;
    if (local.syncVersion > remote.syncVersion) return local;
    return remote.updatedAtMillis >= local.updatedAtMillis
        ? remote
        : local;
  }

  GameStatistics _mergeStatistics({
    required GameStatistics local,
    required GameStatistics remote,
  }) {
    return GameStatistics(
      pvpGames: max(local.pvpGames, remote.pvpGames),
      pvpWhiteWins: max(local.pvpWhiteWins, remote.pvpWhiteWins),
      pvpBlackWins: max(local.pvpBlackWins, remote.pvpBlackWins),
      pvpDraws: max(local.pvpDraws, remote.pvpDraws),
      pvAiWins: max(local.pvAiWins, remote.pvAiWins),
      pvAiLosses: max(local.pvAiLosses, remote.pvAiLosses),
      pvAiDraws: max(local.pvAiDraws, remote.pvAiDraws),
    );
  }

  List<GameHistoryEntry> _mergeHistory({
    required List<GameHistoryEntry> local,
    required List<GameHistoryEntry> remote,
  }) {
    final byId = <String, GameHistoryEntry>{};
    for (final entry in [...local, ...remote]) {
      final existing = byId[entry.id];
      if (existing == null || entry.syncVersion >= existing.syncVersion) {
        byId[entry.id] = entry;
      }
    }
    final merged = byId.values.toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return merged.take(50).toList();
  }

  void dispose() {
    unawaited(_syncState.close());
  }
}
