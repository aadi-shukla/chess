import 'package:chess/features/game/domain/entities/sync_queue_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncQueueEntry', () {
    test('round-trips through JSON', () {
      const entry = SyncQueueEntry(
        id: 'game-1',
        type: SyncOperationType.savedGame,
        payload: {'id': 'game-1'},
        retries: 1,
        createdAtMillis: 123456,
      );

      final parsed = SyncQueueEntry.fromJson(entry.toJson());

      expect(parsed.id, 'game-1');
      expect(parsed.type, SyncOperationType.savedGame);
      expect(parsed.retries, 1);
    });

    test('withRetry increments retry count', () {
      const entry = SyncQueueEntry(
        id: 'x',
        type: SyncOperationType.history,
        payload: {},
        createdAtMillis: 0,
      );

      final retried = entry.withRetry();
      expect(retried.retries, 1);
      expect(retried.canRetry, isTrue);
    });

    test('stops retrying after maxRetries', () {
      const entry = SyncQueueEntry(
        id: 'x',
        type: SyncOperationType.settings,
        payload: {},
        retries: SyncQueueEntry.maxRetries,
        createdAtMillis: 0,
      );

      expect(entry.canRetry, isFalse);
    });
  });
}
