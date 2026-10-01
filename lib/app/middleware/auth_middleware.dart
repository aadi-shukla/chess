import 'package:chess/app/routes/app_routes.dart';
import 'package:chess/features/auth/domain/repositories/auth_repository.dart';
import 'package:chess/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Redirects unauthenticated users away from protected routes.
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (!Get.isRegistered<AuthSessionController>()) {
      return const RouteSettings(name: AppRoutes.login);
    }

    final session = Get.find<AuthSessionController>();
    _syncSessionFromRepository(session);

    if (session.isRestoring.value &&
        !session.isAuthenticated.value &&
        session.user.value == null) {
      return const RouteSettings(name: AppRoutes.splash);
    }

    if (!session.isAuthenticated.value && session.user.value == null) {
      return const RouteSettings(name: AppRoutes.login);
    }

    return null;
  }

  void _syncSessionFromRepository(AuthSessionController session) {
    if (session.isAuthenticated.value || session.user.value != null) {
      return;
    }

    if (!Get.isRegistered<AuthRepository>()) return;

    final current = Get.find<AuthRepository>().currentUser;
    if (current != null) {
      session.applyUser(current);
    }
  }
}
