/// Application-wide constants.
library;

/// Shared compile-time and runtime constants.
abstract final class AppConstants {
  /// Hive box names.
  static const String settingsBoxName = 'settings';
  static const String cacheBoxName = 'cache';
  static const String gameBoxName = 'game';

  /// Hive keys.
  static const String themeModeKey = 'theme_mode';
  static const String savedGameKey = 'saved_game';
  static const String gameStatsKey = 'game_stats';
  static const String boardThemeKey = 'board_theme';
  static const String defaultMinutesKey = 'default_minutes';
  static const String defaultIncrementKey = 'default_increment';
  static const String defaultAiDifficultyKey = 'default_ai_difficulty';
  static const String hapticsEnabledKey = 'haptics_enabled';
  static const String autoSaveEnabledKey = 'auto_save_enabled';
  static const String gameHistoryKey = 'game_history';
  static const String syncQueueKey = 'sync_queue';
  static const String cloudSettingsCacheKey = 'cloud_settings_cache';
  static const String lastCloudSyncKey = 'last_cloud_sync';

  /// Responsive breakpoints (logical pixels).
  static const double mobileBreakpoint = 450;
  static const double tabletBreakpoint = 800;
  static const double desktopBreakpoint = 1200;
}
