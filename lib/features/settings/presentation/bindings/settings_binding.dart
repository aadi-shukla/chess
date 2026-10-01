import 'package:chess/features/settings/presentation/controllers/settings_controller.dart';
import 'package:get/get.dart';

/// Registers controllers for the settings route.
class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettingsController>(SettingsController.new);
  }
}
