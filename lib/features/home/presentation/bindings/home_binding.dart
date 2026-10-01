import 'package:chess/features/game/presentation/bindings/game_binding.dart';
import 'package:chess/features/game/presentation/controllers/play_tab_controller.dart';
import 'package:chess/features/home/presentation/controllers/home_controller.dart';
import 'package:chess/features/leaderboard/domain/repositories/leaderboard_repository.dart';
import 'package:chess/features/leaderboard/presentation/controllers/leaderboard_controller.dart';
import 'package:get/get.dart';

/// Registers [HomeController] for the home route.
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    GameBinding.register();
    LeaderboardBinding.register();
    Get
      ..lazyPut<HomeController>(HomeController.new)
      ..lazyPut(() => PlayTabController(Get.find()))
      ..lazyPut(() => LeaderboardController(
            Get.isRegistered<LeaderboardRepository>()
                ? Get.find<LeaderboardRepository>()
                : null,
          ));
  }
}
