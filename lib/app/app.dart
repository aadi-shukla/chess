import 'package:chess/app/config/env_config.dart';
import 'package:chess/app/routes/app_pages.dart';
import 'package:chess/app/theme/app_theme.dart';
import 'package:chess/core/constants/app_constants.dart';
import 'package:chess/features/settings/presentation/controllers/theme_controller.dart';
import 'package:chess/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';

/// Root widget configuring GetX, themes, localization, and responsiveness.
class ChessApp extends StatelessWidget {
  const ChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(
      () => GetMaterialApp(
        title: EnvConfig.appName,
        debugShowCheckedModeBanner: EnvConfig.isDev,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeController.themeMode.value,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        initialRoute: AppPages.initial,
        getPages: AppPages.routes,
        defaultTransition: Transition.fadeIn,
        transitionDuration: const Duration(milliseconds: 280),
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          final clampedScaler = mediaQuery.textScaler.clamp(
            minScaleFactor: 0.9,
            maxScaleFactor: 1.35,
          );

          return MediaQuery(
            data: mediaQuery.copyWith(textScaler: clampedScaler),
            child: ResponsiveBreakpoints.builder(
              child: ClampingScrollWrapper.builder(context, child!),
              breakpoints: const [
                Breakpoint(
                  start: 0,
                  end: AppConstants.mobileBreakpoint,
                  name: MOBILE,
                ),
                Breakpoint(
                  start: AppConstants.mobileBreakpoint + 1,
                  end: AppConstants.tabletBreakpoint,
                  name: TABLET,
                ),
                Breakpoint(
                  start: AppConstants.tabletBreakpoint + 1,
                  end: AppConstants.desktopBreakpoint,
                  name: DESKTOP,
                ),
                Breakpoint(
                  start: AppConstants.desktopBreakpoint + 1,
                  end: double.infinity,
                  name: '4K',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
