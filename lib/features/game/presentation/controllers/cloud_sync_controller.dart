import 'dart:async';

import 'package:chess/core/network/connectivity_service.dart';
import 'package:chess/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:chess/features/game/domain/repositories/game_repository.dart';
import 'package:get/get.dart';

/// Watches auth and connectivity to trigger cloud sync.
class CloudSyncController extends GetxController {
  CloudSyncController({
    required GameRepository repository,
    required ConnectivityService connectivity,
  })  : _repository = repository,
        _connectivity = connectivity;

  final GameRepository _repository;
  final ConnectivityService _connectivity;

  StreamSubscription<bool>? _connectivitySub;
  Worker? _authWorker;

  @override
  void onInit() {
    super.onInit();
    _bindAuth();
    _connectivitySub = _connectivity.onConnectivityChanged.listen((online) {
      if (online) unawaited(_syncIfPossible());
    });
    unawaited(_syncIfPossible());
  }

  void _bindAuth() {
    if (!Get.isRegistered<AuthSessionController>()) return;
    final session = Get.find<AuthSessionController>();
    _authWorker = ever(session.user, (_) => unawaited(_syncIfPossible()));
    final uid = session.user.value?.uid;
    if (uid != null) _repository.setSyncUid(uid);
  }

  Future<void> syncNow() => _syncIfPossible();

  Future<void> _syncIfPossible() async {
    if (!_repository.cloudSyncAvailable) return;
    if (!Get.isRegistered<AuthSessionController>()) return;

    final session = Get.find<AuthSessionController>();
    final uid = session.user.value?.uid;
    if (uid == null || !session.isAuthenticated.value) return;

    _repository.setSyncUid(uid);
    if (!_connectivity.isOnline) {
      await _repository.flushPendingSync(uid);
      return;
    }
    await _repository.syncToCloud(uid);
  }

  @override
  void onClose() {
    unawaited(_connectivitySub?.cancel());
    _authWorker?.dispose();
    super.onClose();
  }
}
