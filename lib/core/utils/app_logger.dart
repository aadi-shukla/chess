import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Centralized logging configured per environment.
abstract final class AppLogger {
  static late final Logger instance;

  /// Configures the global logger. Call once during bootstrap.
  static void configure({required String levelName}) {
    instance = Logger(
      filter: _LevelFilter(levelName),
      printer: PrettyPrinter(
        methodCount: kReleaseMode ? 0 : 1,
        errorMethodCount: kReleaseMode ? 3 : 5,
      ),
    );
  }
}

class _LevelFilter extends LogFilter {
  _LevelFilter(this.levelName);

  final String levelName;

  @override
  bool shouldLog(LogEvent event) {
    if (kReleaseMode && levelName == 'debug') {
      return event.level.index >= Level.info.index;
    }

    return switch (levelName) {
      'debug' => true,
      'info' => event.level.index >= Level.info.index,
      'warning' => event.level.index >= Level.warning.index,
      'error' => event.level.index >= Level.error.index,
      _ => event.level.index >= Level.info.index,
    };
  }
}
