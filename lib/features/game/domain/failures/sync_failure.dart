import 'package:chess/core/errors/failure.dart';

/// Cloud sync operation failure.
final class SyncFailure extends Failure {
  const SyncFailure(super.message, {super.code});

  const SyncFailure.offline()
      : this('Cloud sync requires an internet connection.', code: 'offline');

  const SyncFailure.notAuthenticated()
      : this('Sign in to sync your games to the cloud.', code: 'not_authenticated');

  const SyncFailure.conflict()
      : this('Sync conflict detected. Remote data was kept.', code: 'conflict');

  const SyncFailure.maxRetries()
      : this('Sync failed after multiple retries.', code: 'max_retries');
}
