import 'package:chess/features/game/domain/entities/board_theme.dart';
import 'package:flutter/material.dart';

/// Resolves [BoardTheme] to display colors.
abstract final class BoardThemePalette {
  static (Color light, Color dark) colors(BoardTheme theme) => switch (theme) {
        BoardTheme.classic => (
            const Color(0xFFEEEED2),
            const Color(0xFF769656),
          ),
        BoardTheme.forest => (
            const Color(0xFFE8F5E9),
            const Color(0xFF558B2F),
          ),
        BoardTheme.ocean => (
            const Color(0xFFE3F2FD),
            const Color(0xFF1565C0),
          ),
        BoardTheme.midnight => (
            const Color(0xFFB0BEC5),
            const Color(0xFF37474F),
          ),
      };
}
