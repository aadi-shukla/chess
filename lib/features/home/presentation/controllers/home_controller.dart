import 'dart:async';

import 'package:chess/features/game/presentation/controllers/play_tab_controller.dart';
import 'package:chess/features/leaderboard/presentation/controllers/leaderboard_controller.dart';
import 'package:get/get.dart';

/// Controls home shell navigation index and dashboard state.
class HomeController extends GetxController {
  int selectedIndex = 0;

  void onDestinationSelected(int index) {
    selectedIndex = index;
    if (index == 1 && Get.isRegistered<PlayTabController>()) {
      unawaited(Get.find<PlayTabController>().reload());
    }
    if (index == 2 && Get.isRegistered<LeaderboardController>()) {
      unawaited(Get.find<LeaderboardController>().reload());
    }
    update();
  }
}
