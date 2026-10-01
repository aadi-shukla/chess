import 'package:chess/core/firebase/firebase_bootstrap.dart';
import 'package:chess/core/firebase/firestore_service.dart';
import 'package:chess/core/network/connectivity_service.dart';
import 'package:chess/features/game/data/datasources/game_local_datasource.dart';
import 'package:chess/features/game/data/datasources/game_remote_datasource.dart';
import 'package:chess/features/game/data/repositories/game_repository_impl.dart';
import 'package:chess/features/game/data/services/cloud_sync_service.dart';
import 'package:chess/features/game/domain/repositories/game_repository.dart';
import 'package:chess/features/game/presentation/controllers/cloud_sync_controller.dart';
import 'package:chess/features/game/presentation/controllers/game_settings_controller.dart';
import 'package:chess/features/game/presentation/controllers/play_tab_controller.dart';
import 'package:get/get.dart';

/// Registers offline game dependencies app-wide.
class GameBinding {
  static void register() {
    if (Get.isRegistered<GameRepository>()) return;

    final local = GameLocalDataSource();

    if (FirebaseBootstrap.isInitialized &&
        Get.isRegistered<FirestoreService>()) {
      final remote = GameRemoteDataSource(Get.find<FirestoreService>());
      final cloudSync = CloudSyncService(
        local: local,
        remote: remote,
        connectivity: Get.find<ConnectivityService>(),
      );
      Get
        ..put<GameRepository>(
          GameRepositoryImpl(local: local, cloudSync: cloudSync),
          permanent: true,
        )
        ..put<CloudSyncController>(
          CloudSyncController(
            repository: Get.find<GameRepository>(),
            connectivity: Get.find<ConnectivityService>(),
          ),
          permanent: true,
        );
    } else {
      Get.put<GameRepository>(
        LocalOnlyGameRepository(local),
        permanent: true,
      );
    }

    Get.put<GameSettingsController>(
      GameSettingsController(Get.find<GameRepository>()),
      permanent: true,
    );
  }
}

/// Play tab controller binding.
class PlayTabBinding extends Bindings {
  @override
  void dependencies() {
    GameBinding.register();
    if (!Get.isRegistered<PlayTabController>()) {
      Get.lazyPut(() => PlayTabController(Get.find<GameRepository>()));
    }
  }
}
