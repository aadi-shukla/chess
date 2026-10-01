import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

/// Responsive layout helpers used across the app shell and pages.
abstract final class AppBreakpoints {
  static bool isMobile(BuildContext context) =>
      ResponsiveBreakpoints.of(context).isMobile;

  static bool isTablet(BuildContext context) =>
      ResponsiveBreakpoints.of(context).equals(TABLET);

  static bool isDesktop(BuildContext context) =>
      ResponsiveBreakpoints.of(context).largerThan(TABLET);

  static bool isWideWeb(BuildContext context) =>
      ResponsiveBreakpoints.of(context).largerThan(DESKTOP);

  /// Max content width for readable layouts on large screens.
  static double contentMaxWidth(BuildContext context) {
    if (isWideWeb(context)) return 1120;
    if (isDesktop(context)) return 960;
    if (isTablet(context)) return 720;
    return double.infinity;
  }

  /// Horizontal padding that scales with viewport width.
  static EdgeInsets pagePadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    }
    if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }

  /// Whether to use a side [NavigationRail] instead of bottom bar.
  static bool useNavigationRail(BuildContext context) =>
      isTablet(context) || isDesktop(context);
}
