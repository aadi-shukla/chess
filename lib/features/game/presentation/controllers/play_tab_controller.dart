import 'dart:async';

import 'package:chess/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:chess/features/game/domain/entities/game_statistics.dart';
import 'package:chess/features/game/domain/entities/saved_game.dart';
import 'package:chess/features/game/domain/entities/sync_state.dart';
import 'package:chess/features/game/domain/repositories/game_repository.dart';
import 'package:chess/features/game/presentation/controllers/cloud_sync_controller.dart';
import 'package:get/get.dart';

/// Loads play-tab state: saved game, statistics, and sync.
class PlayTabController extends GetxController {
  PlayTabController(this._repository);

  final GameRepository _repository;

  SavedGame? savedGame;
  GameStatistics stats = const GameStatistics();
  SyncState syncState = const SyncState();
  bool isLoading = true;
  bool isSyncing = false;

  StreamSubscription<SyncState>? _syncSub;

  @override
  void onInit() {
    super.onInit();
    if (_repository.cloudSyncAvailable) {
      _syncSub = _repository.syncState.listen((state) {
        syncState = state;
        update();
      });
    }
    unawaited(reload());
  }

  @override
  void onClose() {
    unawaited(_syncSub?.cancel());
    super.onClose();
  }

  Future<void> reload() async {
    isLoading = true;
    update();
    savedGame = await _repository.loadSavedGame();
    stats = await _repository.loadStatistics();
    isLoading = false;
    update();
  }

  Future<void> syncNow() async {
    if (!_repository.cloudSyncAvailable) return;
    if (!Get.isRegistered<AuthSessionController>()) return;
    final uid = Get.find<AuthSessionController>().user.value?.uid;
    if (uid == null) return;

    isSyncing = true;
    update();

    if (Get.isRegistered<CloudSyncController>()) {
      await Get.find<CloudSyncController>().syncNow();
    } else {
      await _repository.syncToCloud(uid);
    }
    await reload();

    isSyncing = false;
    update();
  }

  bool get canSync =>
      _repository.cloudSyncAvailable &&
      Get.isRegistered<AuthSessionController>() &&
      (Get.find<AuthSessionController>().user.value?.uid != null);
}
