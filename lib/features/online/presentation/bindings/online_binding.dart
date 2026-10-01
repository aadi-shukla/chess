import 'package:chess/core/firebase/firebase_bootstrap.dart';
import 'package:chess/core/firebase/firestore_service.dart';
import 'package:chess/core/firebase/functions_service.dart';
import 'package:chess/core/network/connectivity_service.dart';
import 'package:chess/features/game/domain/repositories/game_repository.dart';
import 'package:chess/features/game/presentation/bindings/game_binding.dart';
import 'package:chess/features/online/data/datasources/online_game_remote_datasource.dart';
import 'package:chess/features/online/data/repositories/online_game_repository_impl.dart';
import 'package:chess/features/online/domain/repositories/online_game_repository.dart';
import 'package:chess/features/online/presentation/controllers/matchmaking_controller.dart';
import 'package:chess/features/online/presentation/controllers/online_game_controller.dart';
import 'package:get/get.dart';

/// Registers online multiplayer dependencies.
class OnlineBinding extends Bindings {
  @override
  void dependencies() {
    GameBinding.register();

    if (!Get.isRegistered<OnlineGameRepository>() &&
        FirebaseBootstrap.isInitialized &&
        Get.isRegistered<FirestoreService>() &&
        Get.isRegistered<FunctionsService>()) {
      Get.put<OnlineGameRepository>(
        OnlineGameRepositoryImpl(
          OnlineGameRemoteDataSource(
            firestore: Get.find<FirestoreService>(),
            functions: Get.find<FunctionsService>(),
          ),
        ),
        permanent: true,
      );
    }

    Get.lazyPut(
      () => MatchmakingController(Get.find<OnlineGameRepository>()),
    );
  }
}

class OnlineGameBinding extends Bindings {
  @override
  void dependencies() {
    OnlineBinding().dependencies();
    Get.lazyPut(
      () => OnlineGameController(
        repository: Get.find<OnlineGameRepository>(),
        gameRepository: Get.find<GameRepository>(),
        connectivity: Get.find<ConnectivityService>(),
      ),
    );
  }
}
