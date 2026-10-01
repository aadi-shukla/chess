import 'package:chess/features/online/domain/entities/matchmaking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Matchmaking edge cases', () {
    test('QueueStatus idle factory', () {
      const status = QueueStatus.idle();
      expect(status.isIdle, isTrue);
      expect(status.queueId, isNull);
    });

    test('MatchInvite detects expiry', () {
      final expired = MatchInvite(
        inviteCode: 'OLD111',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        mode: 'rated',
        timeControl: '10+0',
      );

      expect(expired.isExpired, isTrue);
      expect(expired.isStarted, isFalse);
    });

    test('MatchInvite fromMap handles missing fields', () {
      final invite = MatchInvite.fromMap({});

      expect(invite.inviteCode, '');
      expect(invite.mode, 'casual');
      expect(invite.timeControl, '10+0');
    });

    test('MatchSearchType parses random', () {
      expect(MatchSearchType.fromString('random'), MatchSearchType.random);
      expect(MatchSearchType.fromString(null), MatchSearchType.rated);
    });
  });
}
