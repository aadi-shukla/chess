import 'package:chess/core/network/connectivity_service.dart';
import 'package:chess/features/settings/presentation/controllers/theme_controller.dart';
import 'package:get/get.dart';

/// Registers application-wide dependencies available across all routes.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get
      ..put<ConnectivityService>(
        ConnectivityServiceImpl(),
        permanent: true,
      )
      ..put<ThemeController>(
        ThemeController(),
        permanent: true,
      );
  }

  /// Initializes async services after bindings are registered.
  static Future<void> initializeAsyncServices() async {
    final connectivity = Get.find<ConnectivityService>();
    if (connectivity is ConnectivityServiceImpl) {
      await connectivity.init();
    }

    final themeController = Get.find<ThemeController>();
    await themeController.init();
  }
}
