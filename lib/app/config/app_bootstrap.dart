import 'package:chess/app/config/env_config.dart';
import 'package:chess/core/firebase/firebase_bootstrap.dart';
import 'package:chess/core/utils/app_logger.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Initializes platform services before [runApp].
abstract final class AppBootstrap {
  /// Runs all startup tasks in the correct order.
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    AppLogger.configure(levelName: EnvConfig.apiLogLevel);
    AppLogger.instance.i('Bootstrapping flavor: ${EnvConfig.flavor}');

    await Hive.initFlutter();

    final firebaseReady = await FirebaseBootstrap.initialize();
    if (!firebaseReady && EnvConfig.enableFirebase) {
      AppLogger.instance.w(
        'Firebase enabled but not initialized. Auth will be unavailable.',
      );
    }
  }
}
