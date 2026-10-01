import 'dart:async';

import 'package:chess/core/errors/result.dart';
import 'package:chess/core/utils/app_logger.dart';
import 'package:chess/features/auth/domain/entities/user_entity.dart';
import 'package:chess/features/auth/domain/failures/auth_failure.dart';
import 'package:chess/features/auth/domain/repositories/auth_repository.dart';
import 'package:get/get.dart';

/// Global authentication session — auto-login and session restore.
class AuthSessionController extends GetxController {
  final Rxn<UserEntity> user = Rxn<UserEntity>();
  final RxBool isRestoring = true.obs;
  final RxBool isAuthenticated = false.obs;

  StreamSubscription<UserEntity?>? _authSubscription;
  AuthRepository? _repository;

  /// Whether Firebase auth is available in this build.
  bool get isAuthAvailable => _repository?.isAvailable ?? false;

  /// Initializes session restore and listens for auth state changes.
  Future<void> init() async {
    if (!Get.isRegistered<AuthRepository>()) {
      isRestoring.value = false;
      return;
    }

    _repository = Get.find<AuthRepository>();
    isRestoring.value = true;

    try {
      if (_repository!.isAvailable) {
        final restoreResult = await _repository!.restoreSession().timeout(
          const Duration(seconds: 8),
          onTimeout: () {
            AppLogger.instance.w('Session restore timed out during init.');
            return const Error(UnknownAuthFailure('Session restore timed out.'));
          },
        );
        restoreResult.dataOrNull?.let(_setUser);

        await _authSubscription?.cancel();
        _authSubscription = _repository!.authStateChanges.listen(
          (entity) {
            if (entity == null) {
              // Ignore transient nulls while Firebase still has a signed-in user.
              if (_repository?.currentUser != null) return;
              _clearUser();
            } else {
              _setUser(entity);
            }
          },
          onError: (Object error) {
            AppLogger.instance.e('Auth state stream error', error: error);
          },
          cancelOnError: false,
        );

        final current = _repository!.currentUser;
        if (current != null) {
          _setUser(current);
        }
      }
    } finally {
      isRestoring.value = false;
    }
  }

  void _setUser(UserEntity entity) {
    user.value = entity;
    isAuthenticated.value = true;
  }

  void _clearUser() {
    user.value = null;
    isAuthenticated.value = false;
  }

  void applyUser(UserEntity entity) => _setUser(entity);

  void clearUser() => _clearUser();

  @override
  void onClose() {
    unawaited(_authSubscription?.cancel());
    super.onClose();
  }
}

extension _Let<T> on T {
  void let(void Function(T value) block) => block(this);
}
