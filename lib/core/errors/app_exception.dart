/// Base exception for domain and data layer errors.
library;

/// Application-level exception with an optional machine-readable [code].
sealed class AppException implements Exception {
  const AppException(this.message, {this.code});

  /// Human-readable error description.
  final String message;

  /// Optional error code for logging or mapping.
  final String? code;

  @override
  String toString() => 'AppException($code): $message';
}
