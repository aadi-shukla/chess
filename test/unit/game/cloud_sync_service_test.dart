import 'package:chess/chess_engine/chess_engine.dart';
import 'package:chess/core/errors/result.dart';
import 'package:chess/features/game/data/datasources/game_local_datasource.dart';
import 'package:chess/features/game/data/datasources/game_remote_datasource.dart';
import 'package:chess/features/game/data/services/cloud_sync_service.dart';
import 'package:chess/features/game/domain/entities/cloud_game_settings.dart';
import 'package:chess/features/game/domain/entities/game_history_entry.dart';
import 'package:chess/features/game/domain/entities/game_mode.dart';
import 'package:chess/features/game/domain/entities/game_statistics.dart';
import 'package:chess/features/game/domain/entities/saved_game.dart';
import 'package:chess/features/game/domain/entities/sync_queue_entry.dart';
import 'package:chess/features/game/domain/entities/sync_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_harness.dart';

void main() {
  late GameLocalDataSource local;
  late FakeGameRemoteTracker remote;
  late FakeConnectivityService connectivity;
  late CloudSyncService sync;

  setUp(() async {
    await TestHarness.initHive(path: TestHarness.uniqueHivePath('cloud_sync'));
    local = GameLocalDataSource();
    remote = FakeGameRemoteTracker();
    connectivity = FakeConnectivityService();
    sync = CloudSyncService(
      local: local,
      remote: remote,
      connectivity: connectivity,
    );
  });

  tearDown(() async => TestHarness.clearHiveBoxes());

  group('CloudSyncService', () {
    test('queues saved game while offline without remote write', () async {
      connectivity.online = false;

      final game = SavedGame(
        id: 'offline-1',
        mode: GameMode.playerVsPlayer,
        snapshot: const ChessGameSnapshot(
          moveUcis: ['e2e4'],
          whiteMillis: 600000,
          blackMillis: 600000,
          incrementMillis: 0,
        ),
        savedAt: DateTime.now(),
        aiDifficulty: AiDifficulty.medium,
        humanColor: ChessColor.white,
      );

      await sync.queueSavedGame(game, uid: 'user-1');

      final queue = await local.readSyncQueue();
      expect(queue, hasLength(1));
      expect(remote.savedGames, isEmpty);
    });

    test('flushQueue pushes queued game when online', () async {
      final game = SavedGame(
        id: 'sync-1',
        mode: GameMode.playerVsAi,
        snapshot: const ChessGameSnapshot(
          moveUcis: [],
          whiteMillis: 300000,
          blackMillis: 300000,
          incrementMillis: 0,
        ),
        savedAt: DateTime.now(),
        aiDifficulty: AiDifficulty.easy,
        humanColor: ChessColor.white,
      );

      await local.writeSyncQueue([
        SyncQueueEntry(
          id: game.id,
          type: SyncOperationType.savedGame,
          payload: game.toJson(),
          createdAtMillis: DateTime.now().millisecondsSinceEpoch,
        ),
      ]);

      await sync.flushQueue(uid: 'user-1');

      expect(remote.savedGames, hasLength(1));
      expect(remote.savedGames.first.id, 'sync-1');
    });

    test('syncAll returns offline error when disconnected', () async {
      connectivity.online = false;

      final result = await sync.syncAll(uid: 'user-1');

      expect(result, isA<Error<void>>());
      expect(sync.currentState.status, SyncStatus.offline);
    });

    test('syncAll merges statistics instead of overwriting local counts',
        () async {
      // Local device has played more games than the (stale) remote copy.
      await local.writeStatistics(
        const GameStatistics(
          pvpGames: 10,
          pvpWhiteWins: 6,
          pvAiWins: 1,
        ),
      );

      // Remote settings "win" the conflict (higher syncVersion) but carry
      // fewer PvP games and more AI wins. A merge must keep the max of each.
      final settingsRemote = FakeSettingsRemote(
        remoteSettings: const CloudGameSettings(
          statistics: GameStatistics(
            pvpGames: 3,
            pvpWhiteWins: 2,
            pvAiWins: 5,
          ),
          syncVersion: 99,
        ),
      );
      final mergingSync = CloudSyncService(
        local: local,
        remote: settingsRemote,
        connectivity: connectivity,
      );

      final result = await mergingSync.syncAll(uid: 'user-1');
      expect(result, isA<Success<void>>());

      final merged = await local.readStatistics();
      expect(merged.pvpGames, 10, reason: 'higher local count preserved');
      expect(merged.pvpWhiteWins, 6, reason: 'higher local count preserved');
      expect(merged.pvAiWins, 5, reason: 'higher remote count preserved');
    });
  });
}

class FakeGameRemoteTracker extends GameRemoteDataSource {
  FakeGameRemoteTracker() : super(fakeFirestoreService());

  final List<SavedGame> savedGames = [];

  @override
  Future<void> upsertSavedGame({
    required String uid,
    required SavedGame game,
  }) async {
    savedGames.add(game);
  }
}

class FakeSettingsRemote extends GameRemoteDataSource {
  FakeSettingsRemote({required this.remoteSettings})
      : super(fakeFirestoreService());

  final CloudGameSettings remoteSettings;

  @override
  Future<SavedGame?> fetchActiveSavedGame(String uid) async => null;

  @override
  Future<CloudGameSettings?> fetchSettings(String uid) async => remoteSettings;

  @override
  Future<List<GameHistoryEntry>> fetchHistory(String uid, {int limit = 50}) async =>
      const [];

  @override
  Future<void> upsertSavedGame({
    required String uid,
    required SavedGame game,
  }) async {}

  @override
  Future<void> upsertSettings({
    required String uid,
    required CloudGameSettings settings,
  }) async {}

  @override
  Future<void> upsertHistoryEntry({
    required String uid,
    required GameHistoryEntry entry,
  }) async {}
}
