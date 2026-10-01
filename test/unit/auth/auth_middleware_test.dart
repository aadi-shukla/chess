import 'package:chess/app/middleware/auth_middleware.dart';
import 'package:chess/app/routes/app_routes.dart';
import 'package:chess/features/auth/domain/entities/user_entity.dart';
import 'package:chess/features/auth/domain/repositories/auth_repository.dart';
import 'package:chess/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.signedInUser});

  UserEntity? signedInUser;

  @override
  bool get isAvailable => true;

  @override
  UserEntity? get currentUser => signedInUser;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  tearDown(TestHarness.resetGet);

  test('AuthMiddleware syncs Firebase user when session memory is empty', () {
    final session = AuthSessionController();
    final repository = _FakeAuthRepository(
      signedInUser: const UserEntity(
        uid: 'uid-1',
        email: 'player@chess.com',
        displayName: 'Player',
      ),
    );

    Get
      ..put<AuthSessionController>(session, permanent: true)
      ..put<AuthRepository>(repository, permanent: true);

    session.isRestoring.value = false;

    final redirect = AuthMiddleware().redirect(AppRoutes.home);

    expect(redirect, isNull);
    expect(session.isAuthenticated.value, isTrue);
    expect(session.user.value?.uid, 'uid-1');
  });

  test('AuthMiddleware redirects to login when no session exists', () {
    final session = AuthSessionController();
    final repository = _FakeAuthRepository();

    Get
      ..put<AuthSessionController>(session, permanent: true)
      ..put<AuthRepository>(repository, permanent: true);

    session.isRestoring.value = false;

    final redirect = AuthMiddleware().redirect(AppRoutes.home);

    expect(redirect, const RouteSettings(name: AppRoutes.login));
  });

  test('AuthMiddleware allows home while restoring if already authenticated', () {
    final session = AuthSessionController()
      ..isRestoring.value = true
      ..applyUser(
        const UserEntity(
          uid: 'uid-1',
          email: 'player@chess.com',
          displayName: 'Player',
        ),
      );

    Get.put<AuthSessionController>(session, permanent: true);

    final redirect = AuthMiddleware().redirect(AppRoutes.home);

    expect(redirect, isNull);
  });
}

/// Minimal Get reset helper for middleware tests.
abstract final class TestHarness {
  static void resetGet() => Get.reset();
}
