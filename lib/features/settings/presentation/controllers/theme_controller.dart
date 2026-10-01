import 'package:chess/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// Persists and exposes the active [ThemeMode].
class ThemeController extends GetxController {
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;
  Box<dynamic>? _settingsBox;

  /// Loads persisted theme preference from Hive.
  Future<void> init() async {
    await openSettingsBox();
    final stored = _settingsBox?.get(AppConstants.themeModeKey) as String?;
    themeMode.value = _parseThemeMode(stored);
  }

  /// Opens the Hive settings box if not already open.
  Future<void> openSettingsBox() async {
    _settingsBox ??= await Hive.openBox<dynamic>(AppConstants.settingsBoxName);
  }

  /// Updates theme mode and persists the choice.
  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    await _settingsBox?.put(AppConstants.themeModeKey, mode.name);
  }

  ThemeMode _parseThemeMode(String? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}
