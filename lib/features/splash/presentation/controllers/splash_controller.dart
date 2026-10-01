import 'dart:async';

import 'package:chess/app/routes/app_routes.dart';
import 'package:chess/core/utils/app_logger.dart';
import 'package:chess/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:get/get.dart';

/// Handles splash initialization, session restore, and routing.
class SplashController extends GetxController {
  static const _splashDelay = Duration(milliseconds: 900);
  static const _sessionRestoreTimeout = Duration(seconds: 10);
  static const _sessionPollInterval = Duration(milliseconds: 50);

  Timer? _navigationTimer;

  @override
  void onReady() {
    super.onReady();
    // Defer the initial delay via a cancellable timer so it is disposed with
    // the controller instead of leaking if the splash is torn down early.
    _navigationTimer = Timer(_splashDelay, () {
      unawaited(_resolveNavigation());
    });
  }

  @override
  void onClose() {
    _navigationTimer?.cancel();
    super.onClose();
  }

  Future<void> _resolveNavigation() async {
    try {
      if (isClosed) return;

      if (!Get.isRegistered<AuthSessionController>()) {
        await Get.offNamed<void>(AppRoutes.login);
        return;
      }

      final session = Get.find<AuthSessionController>();
      final deadline = DateTime.now().add(_sessionRestoreTimeout);

      while (session.isRestoring.value) {
        if (isClosed) return;
        if (DateTime.now().isAfter(deadline)) {
          AppLogger.instance.w(
            'Session restore timed out — continuing without session.',
          );
          break;
        }
        await Future<void>.delayed(_sessionPollInterval);
      }

      if (isClosed) return;

      if (session.isAuthenticated.value) {
        final activeGameId = session.user.value?.activeGameId;
        if (activeGameId != null && activeGameId.isNotEmpty) {
          AppLogger.instance.i('Active online game — resuming $activeGameId');
          await Get.offNamed<void>(
            AppRoutes.onlineGame,
            parameters: {'gameId': activeGameId},
          );
          return;
        }

        AppLogger.instance.i('Session restored — navigating to home.');
        await Get.offNamed<void>(AppRoutes.home);
      } else {
        AppLogger.instance.i('No session — navigating to login.');
        await Get.offNamed<void>(AppRoutes.login);
      }
    } catch (error, stackTrace) {
      AppLogger.instance.e(
        'Splash navigation failed — falling back to login.',
        error: error,
        stackTrace: stackTrace,
      );
      if (isClosed) return;
      await Get.offNamed<void>(AppRoutes.login);
    }
  }
}
