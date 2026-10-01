import 'package:chess/features/settings/presentation/controllers/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Settings screen state; delegates theme changes to [ThemeController].
class SettingsController extends GetxController {
  ThemeController get _themeController => Get.find<ThemeController>();

  ThemeMode get themeMode => _themeController.themeMode.value;

  Future<void> setThemeMode(ThemeMode mode) =>
      _themeController.setThemeMode(mode);
}
