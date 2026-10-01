import 'package:chess/features/auth/domain/failures/auth_failure.dart';

/// Client-side and server-side authentication validation.
abstract final class AuthValidator {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static const int minPasswordLength = 8;
  static const int minDisplayNameLength = 2;
  static const int maxDisplayNameLength = 32;

  /// Returns a validation error message, or `null` if valid.
  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Email is required.';
    }
    if (!_emailRegex.hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  /// Returns a validation error message, or `null` if valid.
  static String? validatePassword(String? value, {bool isRegistration = false}) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Password is required.';
    }
    if (password.length < minPasswordLength) {
      return 'Password must be at least $minPasswordLength characters.';
    }
    if (isRegistration) {
      if (!RegExp('[A-Za-z]').hasMatch(password)) {
        return 'Password must contain at least one letter.';
      }
      if (!RegExp('[0-9]').hasMatch(password)) {
        return 'Password must contain at least one number.';
      }
    }
    return null;
  }

  static final RegExp _displayNameRegex = RegExp(
    r"^[\w .'\-]{2,32}$",
    unicode: true,
  );

  /// Returns a validation error message, or `null` if valid.
  static String? validateDisplayName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) {
      return 'Display name is required.';
    }
    if (name.length < minDisplayNameLength) {
      return 'Display name must be at least $minDisplayNameLength characters.';
    }
    if (name.length > maxDisplayNameLength) {
      return 'Display name must be at most $maxDisplayNameLength characters.';
    }
    if (!_displayNameRegex.hasMatch(name)) {
      return 'Display name contains invalid characters.';
    }
    return null;
  }

  /// Returns a validation error message, or `null` if valid.
  static String? validateConfirmPassword(String? password, String? confirm) {
    if (confirm == null || confirm.isEmpty) {
      return 'Please confirm your password.';
    }
    if (confirm != password) {
      return 'Passwords do not match.';
    }
    return null;
  }

  /// Maps a validation message to [ValidationFailure].
  static ValidationFailure? validationFailure(String? message) {
    if (message == null) return null;
    return ValidationFailure(message);
  }
}
