import 'package:chess/features/online/domain/entities/matchmaking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QueueStatus', () {
    test('parses waiting state with rating band', () {
      final status = QueueStatus.fromMap({
        'status': 'waiting',
        'queueId': 'q1',
        'mode': 'rated',
        'matchType': 'rated',
        'timeControl': '10+0',
        'ratingBand': 200,
        'waitSeconds': 18,
        'expiresAt': 1_700_000_120_000,
      });

      expect(status.isWaiting, isTrue);
      expect(status.queueId, 'q1');
      expect(status.ratingBand, 200);
      expect(status.waitSeconds, 18);
    });

    test('parses matched state', () {
      final status = QueueStatus.fromMap({
        'status': 'matched',
        'gameId': 'g1',
      });

      expect(status.isMatched, isTrue);
      expect(status.gameId, 'g1');
    });
  });

  group('MatchInvite', () {
    test('detects started invite', () {
      final invite = MatchInvite(
        inviteCode: 'ABC123',
        expiresAt: DateTime.now().add(const Duration(minutes: 10)),
        mode: 'casual',
        timeControl: '5+0',
        gameId: 'game-1',
        status: 'started',
      );

      expect(invite.isStarted, isTrue);
    });
  });
}
