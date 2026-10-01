import 'package:flutter/material.dart';

/// Reads compile-time environment values injected via `--dart-define-from-file`.
abstract final class EnvConfig {
  static const String flavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'dev',
  );

  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Chess',
  );

  static const String enableFirebaseRaw = String.fromEnvironment(
    'ENABLE_FIREBASE',
    defaultValue: 'true',
  );

  static const String apiLogLevel = String.fromEnvironment(
    'API_LOG_LEVEL',
    defaultValue: 'debug',
  );

  static const String useFirebaseEmulatorsRaw = String.fromEnvironment(
    'USE_FIREBASE_EMULATORS',
    defaultValue: 'false',
  );

  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );

  /// Whether Firebase should be initialized at startup.
  static bool get enableFirebase => enableFirebaseRaw.toLowerCase() == 'true';

  /// Whether to connect to local Firebase emulators after initialization.
  static bool get useFirebaseEmulators =>
      useFirebaseEmulatorsRaw.toLowerCase() == 'true';

  static bool get isDev => flavor == 'dev';
  static bool get isStaging => flavor == 'staging';
  static bool get isProd => flavor == 'prod';

  /// Visual banner color for non-production builds.
  static Color? get flavorBannerColor => switch (flavor) {
        'dev' => Colors.orange.shade700,
        'staging' => Colors.blue.shade700,
        _ => null,
      };
}
