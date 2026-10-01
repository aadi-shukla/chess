/// Failure types returned from repositories and use cases.
library;

/// Base failure type for operation error channels.
abstract class Failure {
  const Failure(this.message, {this.code});

  /// Human-readable failure description.
  final String message;

  /// Optional failure code.
  final String? code;
}

/// Unexpected or uncategorized failure.
final class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.code});
}

/// Local persistence failure.
final class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code});
}

/// Network or remote service failure.
final class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}
