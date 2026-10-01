import 'package:chess/app/config/env_config.dart';
import 'package:chess/features/auth/domain/failures/auth_failure.dart';

/// Maps [AuthFailure] instances to user-facing snackbar/dialog messages.
abstract final class AuthFailureMapper {
  static String message(AuthFailure failure) {
    return switch (failure) {
      InvalidEmailFailure() => 'Please enter a valid email address.',
      WrongPasswordFailure() => 'Incorrect password. Please try again.',
      UserNotFoundFailure() => 'No account found with this email.',
      EmailAlreadyInUseFailure() =>
        'This email is already registered. Try signing in.',
      WeakPasswordFailure() =>
        'Password is too weak. Use at least 8 characters with letters and numbers.',
      AuthNetworkFailure() => EnvConfig.useFirebaseEmulators
          ? 'Cannot reach Firebase emulators. Run: firebase emulators:start'
          : 'Network error. Check your connection and try again.',
      SignUpDisabledFailure() =>
        'Sign-up is turned off in Firebase. Open Firebase Console → '
        'Authentication → Settings → User actions and enable Create (sign-up).',
      AuthProviderDisabledFailure() =>
        'This sign-in method is disabled. Open Firebase Console → '
        'Authentication → Sign-in method and enable Email/Password or Anonymous.',
      GoogleSignInCancelledFailure() => 'Google sign-in was cancelled.',
      GoogleSignInFailure() => failure.message,
      RequiresRecentLoginFailure() =>
        'For security, please sign in again before deleting your account.',
      FirebaseNotConfiguredFailure() =>
        'Online features are not configured. Run Firebase setup.',
      ValidationFailure() => failure.message,
      AccountDeleteFailure() => failure.message,
      UnknownAuthFailure() => failure.message,
    };
  }
}
