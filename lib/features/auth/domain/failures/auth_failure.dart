import 'package:chess/core/errors/failure.dart';

/// Typed authentication failures mapped from Firebase Auth errors.
sealed class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

final class InvalidEmailFailure extends AuthFailure {
  const InvalidEmailFailure()
      : super('Invalid email address.', code: 'invalid-email');
}

final class WrongPasswordFailure extends AuthFailure {
  const WrongPasswordFailure()
      : super('Incorrect password.', code: 'wrong-password');
}

final class EmailAlreadyInUseFailure extends AuthFailure {
  const EmailAlreadyInUseFailure()
      : super('Email is already registered.', code: 'email-already-in-use');
}

final class UserNotFoundFailure extends AuthFailure {
  const UserNotFoundFailure() : super('No account found.', code: 'user-not-found');
}

final class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure()
      : super('Password is too weak.', code: 'weak-password');
}

final class AuthNetworkFailure extends AuthFailure {
  const AuthNetworkFailure()
      : super('Network error. Check your connection.', code: 'network');
}

final class SignUpDisabledFailure extends AuthFailure {
  const SignUpDisabledFailure()
      : super(
          'Account creation is disabled for this Firebase project.',
          code: 'admin-restricted-operation',
        );
}

final class AuthProviderDisabledFailure extends AuthFailure {
  const AuthProviderDisabledFailure()
      : super(
          'This sign-in method is not enabled.',
          code: 'operation-not-allowed',
        );
}

final class GoogleSignInCancelledFailure extends AuthFailure {
  const GoogleSignInCancelledFailure()
      : super('Google sign-in was cancelled.', code: 'google-sign-in-cancelled');
}

final class GoogleSignInFailure extends AuthFailure {
  const GoogleSignInFailure(super.message, {super.code});
}

final class RequiresRecentLoginFailure extends AuthFailure {
  const RequiresRecentLoginFailure()
      : super('Recent login required.', code: 'requires-recent-login');
}

final class FirebaseNotConfiguredFailure extends AuthFailure {
  const FirebaseNotConfiguredFailure()
      : super('Firebase is not configured.', code: 'firebase-not-configured');
}

final class ValidationFailure extends AuthFailure {
  const ValidationFailure(super.message) : super(code: 'validation');
}

final class AccountDeleteFailure extends AuthFailure {
  const AccountDeleteFailure(super.message, {super.code});
}

final class UnknownAuthFailure extends AuthFailure {
  const UnknownAuthFailure(super.message, {super.code});
}

/// Maps a Firebase Auth error code to a typed [AuthFailure].
AuthFailure mapAuthErrorCode(String code, {String? message}) {
  return switch (code) {
    'invalid-email' => const InvalidEmailFailure(),
    'wrong-password' => const WrongPasswordFailure(),
    'invalid-credential' => const WrongPasswordFailure(),
    'user-not-found' => const UserNotFoundFailure(),
    'email-already-in-use' => const EmailAlreadyInUseFailure(),
    'weak-password' => const WeakPasswordFailure(),
    'network-request-failed' => const AuthNetworkFailure(),
    'admin-restricted-operation' => const SignUpDisabledFailure(),
    'operation-not-allowed' => const AuthProviderDisabledFailure(),
    'requires-recent-login' => const RequiresRecentLoginFailure(),
    'account-exists-with-different-credential' =>
      const EmailAlreadyInUseFailure(),
    'credential-already-in-use' => const EmailAlreadyInUseFailure(),
    'popup-closed-by-user' => const GoogleSignInCancelledFailure(),
    _ => UnknownAuthFailure(message ?? 'Authentication failed.', code: code),
  };
}
