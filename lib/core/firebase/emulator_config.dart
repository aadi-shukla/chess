import 'package:flutter/foundation.dart';
abstract final class EmulatorConfig {
  static const int authPort = 9099;
  static const int firestorePort = 8080;
  static const int functionsPort = 5001;

  /// Hostname used to reach the host machine from emulators/simulators.
  static String get host {
    if (kIsWeb) {
      return 'localhost';
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => '10.0.2.2',
      _ => 'localhost',
    };
  }
}
