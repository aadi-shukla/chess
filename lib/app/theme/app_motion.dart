import 'package:flutter/material.dart';

/// Centralized motion tokens with reduced-motion support.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 420);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutBack;

  static bool reducedMotion(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  static Duration duration(BuildContext context, Duration preferred) =>
      reducedMotion(context) ? Duration.zero : preferred;

  static Duration tabSwitch(BuildContext context) =>
      duration(context, medium);

  static Duration fadeIn(BuildContext context) => duration(context, medium);

  static Duration pageTransition(BuildContext context) =>
      duration(context, const Duration(milliseconds: 320));
}
