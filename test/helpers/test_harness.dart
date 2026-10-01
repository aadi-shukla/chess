import 'package:chess/app/theme/app_colors.dart';
import 'package:chess/app/theme/app_theme.dart';
import 'package:chess/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// Shared Hive + GetX setup for tests.
abstract final class TestHarness {
  static Future<void> initHive({String? path}) async {
    Hive.init(path ?? uniqueHivePath('shared'));
  }

  static String uniqueHivePath(String prefix) =>
      './.dart_tool/test_hive/$prefix-${DateTime.now().microsecondsSinceEpoch}';

  static Future<void> clearHiveBoxes() async {
    for (final name in [
      AppConstants.gameBoxName,
      AppConstants.cacheBoxName,
      AppConstants.settingsBoxName,
    ]) {
      if (Hive.isBoxOpen(name)) {
        await Hive.box<dynamic>(name).clear();
        await Hive.box<dynamic>(name).close();
      }
    }
  }

  static void resetGet() {
    if (Get.isRegistered<GetMaterialController>()) {
      Get.reset();
    } else {
      Get.reset();
    }
  }

  /// Deterministic theme for widget/golden tests (no Google Fonts network).
  static ThemeData testLight() => _testTheme(Brightness.light);

  static ThemeData testDark() => _testTheme(Brightness.dark);

  static ThemeData _testTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.seed,
        brightness: brightness,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      ),
      scaffoldBackgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
    );
  }

  static Widget themed(Widget child) {
    return MaterialApp(
      theme: testLight(),
      darkTheme: testDark(),
      home: Scaffold(body: child),
    );
  }

  static Widget getThemed(Widget child) {
    return GetMaterialApp(
      theme: testLight(),
      darkTheme: testDark(),
      home: Scaffold(body: child),
    );
  }

  /// Production theme — only use when Google Fonts runtime fetch is allowed.
  static Widget productionThemed(Widget child) {
    return MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: Scaffold(body: child),
    );
  }
}
