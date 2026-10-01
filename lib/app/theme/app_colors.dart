import 'package:flutter/material.dart';

/// Semantic color tokens for light and dark themes.
abstract final class AppColors {
  // Brand
  static const Color seed = Color(0xFF2D6A4F);
  static const Color primary = Color(0xFF1B4332);
  static const Color primaryContainer = Color(0xFF2D6A4F);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFFD4A373);
  static const Color onSecondary = Color(0xFF1B1B1B);

  // Surfaces
  static const Color lightBackground = Color(0xFFF8F5F0);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkSurfaceElevated = Color(0xFF1C2128);

  // Board (preview tokens for future game UI)
  static const Color boardLightSquare = Color(0xFFEAD7C3);
  static const Color boardDarkSquare = Color(0xFF8B5E3C);

  // Status
  static const Color success = Color(0xFF40916C);
  static const Color error = Color(0xFFE63946);
  static const Color warning = Color(0xFFF4A261);
}
