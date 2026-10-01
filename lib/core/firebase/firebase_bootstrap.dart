import 'package:chess/app/config/env_config.dart';
import 'package:chess/app/config/firebase_options.dart';
import 'package:chess/core/firebase/emulator_config.dart';
import 'package:chess/core/utils/app_logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Initializes Firebase Core and optionally connects to local emulators.
abstract final class FirebaseBootstrap {
  static bool _initialized = false;

  /// Whether [initialize] completed successfully.
  static bool get isInitialized => _initialized;

  /// Initializes Firebase and emulator connections when enabled.
  static Future<bool> initialize() async {
    if (!EnvConfig.enableFirebase) {
      AppLogger.instance.i('Firebase disabled for flavor: ${EnvConfig.flavor}');
      return false;
    }

    if (!DefaultFirebaseOptions.isConfigured) {
      AppLogger.instance.w(
        'Firebase options not configured. Run: ./scripts/firebase_setup.sh',
      );
      return false;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      if (EnvConfig.useFirebaseEmulators) {
        await _connectEmulators();
      } else {
        _configureProductionFirestore();
      }

      _initialized = true;
      AppLogger.instance.i(
        'Firebase initialized (emulators: ${EnvConfig.useFirebaseEmulators}).',
      );
      if (EnvConfig.useFirebaseEmulators) {
        AppLogger.instance.i(
          'Using emulators at ${EmulatorConfig.host} '
          '(auth ${EmulatorConfig.authPort}, '
          'firestore ${EmulatorConfig.firestorePort}). '
          'Start with: firebase emulators:start',
        );
      }
      return true;
    } catch (error, stackTrace) {
      AppLogger.instance.e(
        'Firebase initialization failed.',
        error: error,
        stackTrace: stackTrace,
      );
      if (kDebugMode) rethrow;
      return false;
    }
  }

  static Future<void> _connectEmulators() async {
    final host = EmulatorConfig.host;

    FirebaseFirestore.instance.useFirestoreEmulator(
      host,
      EmulatorConfig.firestorePort,
    );

    await FirebaseAuth.instance.useAuthEmulator(
      host,
      EmulatorConfig.authPort,
    );

    FirebaseFunctions.instance.useFunctionsEmulator(
      host,
      EmulatorConfig.functionsPort,
    );

    AppLogger.instance.i('Connected to Firebase emulators at $host');
  }

  static void _configureProductionFirestore() {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 50 * 1024 * 1024,
    );
  }
}
