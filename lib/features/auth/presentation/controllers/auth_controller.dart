import 'package:chess/app/routes/app_routes.dart';
import 'package:chess/core/errors/failure.dart';
import 'package:chess/core/errors/result.dart';
import 'package:chess/features/auth/domain/entities/user_entity.dart';
import 'package:chess/features/auth/domain/failures/auth_failure.dart';
import 'package:chess/features/auth/domain/repositories/auth_repository.dart';
import 'package:chess/features/auth/domain/validators/auth_validator.dart';
import 'package:chess/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:chess/features/auth/presentation/utils/auth_failure_mapper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shared authentication actions for login, register, and forgot-password flows.
class AuthController extends GetxController {
  AuthRepository get _authRepository => Get.find<AuthRepository>();
  AuthSessionController get _sessionController => Get.find<AuthSessionController>();

  final RxBool isLoading = false.obs;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final displayNameController = TextEditingController();

  final RxString emailError = ''.obs;
  final RxString passwordError = ''.obs;
  final RxString confirmPasswordError = ''.obs;
  final RxString displayNameError = ''.obs;

  bool get isAuthAvailable => _authRepository.isAvailable;

  Future<void> signInWithEmail() async {
    if (!_validateLogin()) return;
    await _runSignIn(
      () => _authRepository.signInWithEmail(
        AuthCredentials(
          email: emailController.text,
          password: passwordController.text,
        ),
      ),
    );
  }

  Future<void> registerWithEmail() async {
    if (!_validateRegister()) return;
    await _runSignIn(
      () => _authRepository.registerWithEmail(
        RegisterCredentials(
          email: emailController.text,
          password: passwordController.text,
          displayName: displayNameController.text,
        ),
      ),
    );
  }

  Future<void> signInWithGoogle() async {
    await _runSignIn(_authRepository.signInWithGoogle);
  }

  Future<void> signInAsGuest() async {
    await _runSignIn(_authRepository.signInAnonymously);
  }

  Future<void> sendPasswordReset() async {
    final emailErr = AuthValidator.validateEmail(emailController.text);
    if (emailErr != null) {
      emailError.value = emailErr;
      return;
    }
    emailError.value = '';

    isLoading.value = true;
    final result = await _authRepository.sendPasswordResetEmail(
      emailController.text,
    );
    isLoading.value = false;

    if (result.isFailure) {
      _showFailure(result.failureOrNull!);
      return;
    }

    Get.snackbar(
      'Email sent',
      'Check your inbox for password reset instructions.',
      snackPosition: SnackPosition.BOTTOM,
    );
    await Get.offNamed<void>(AppRoutes.login);
  }

  Future<void> signOut() async {
    isLoading.value = true;
    final result = await _authRepository.signOut();
    isLoading.value = false;

    if (result.isFailure) {
      _showFailure(result.failureOrNull!);
      return;
    }

    _sessionController.clearUser();
    await Get.offAllNamed<void>(AppRoutes.login);
  }

  Future<void> deleteAccount() async {
    isLoading.value = true;
    final result = await _authRepository.deleteAccount();
    isLoading.value = false;

    if (result.isFailure) {
      _showFailure(result.failureOrNull!);
      return;
    }

    _sessionController.clearUser();
    Get.snackbar(
      'Account deleted',
      'Your account has been permanently removed.',
      snackPosition: SnackPosition.BOTTOM,
    );
    await Get.offAllNamed<void>(AppRoutes.login);
  }

  bool _validateLogin() {
    final emailErr = AuthValidator.validateEmail(emailController.text);
    final passwordErr = AuthValidator.validatePassword(passwordController.text);

    emailError.value = emailErr ?? '';
    passwordError.value = passwordErr ?? '';

    return emailErr == null && passwordErr == null;
  }

  bool _validateRegister() {
    final emailErr = AuthValidator.validateEmail(emailController.text);
    final passwordErr = AuthValidator.validatePassword(
      passwordController.text,
      isRegistration: true,
    );
    final confirmErr = AuthValidator.validateConfirmPassword(
      passwordController.text,
      confirmPasswordController.text,
    );
    final nameErr = AuthValidator.validateDisplayName(displayNameController.text);

    emailError.value = emailErr ?? '';
    passwordError.value = passwordErr ?? '';
    confirmPasswordError.value = confirmErr ?? '';
    displayNameError.value = nameErr ?? '';

    return emailErr == null &&
        passwordErr == null &&
        confirmErr == null &&
        nameErr == null;
  }

  Future<void> _runSignIn(Future<Result<UserEntity>> Function() action) async {
    isLoading.value = true;
    final result = await action();
    isLoading.value = false;

    if (result.isFailure) {
      _showFailure(result.failureOrNull!);
      return;
    }

    final user = result.dataOrNull;
    if (user == null) {
      Get.snackbar(
        'Authentication',
        'Signed in but user profile is unavailable. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    _sessionController.applyUser(user);

    if (!_sessionController.isAuthenticated.value) {
      Get.snackbar(
        'Authentication',
        'Could not establish a session. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await Get.offAllNamed<void>(AppRoutes.home);
  }

  void _showFailure(Failure failure) {
    final message = failure is AuthFailure
        ? AuthFailureMapper.message(failure)
        : failure.message;

    Get.snackbar(
      'Authentication',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.errorContainer,
      colorText: Get.theme.colorScheme.onErrorContainer,
    );
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    displayNameController.dispose();
    super.onClose();
  }
}
