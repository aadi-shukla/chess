import 'package:chess/features/game/presentation/bindings/game_binding.dart';
import 'package:chess/features/game/presentation/controllers/offline_game_controller.dart';
import 'package:get/get.dart';

/// Registers [OfflineGameController] for the offline game route.
class OfflineGameBinding extends Bindings {
  @override
  void dependencies() {
    GameBinding.register();
    Get.lazyPut(() => OfflineGameController(Get.find()));
  }
}
