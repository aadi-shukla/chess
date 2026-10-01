import 'package:chess/features/online/data/repositories/online_game_repository_impl.dart';
import 'package:chess/features/online/domain/entities/matchmaking.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

void main() {
  group('OnlineGameRepositoryImpl', () {
    late SpyOnlineGameRemoteDataSource remote;
    late OnlineGameRepositoryImpl repository;

    setUp(() {
      remote = SpyOnlineGameRemoteDataSource();
      repository = OnlineGameRepositoryImpl(remote);
    });

    test('joinMatchmakingQueue forwards parameters', () async {
      final result = await repository.joinMatchmakingQueue(
        mode: 'rated',
        timeControl: '10+0',
        matchType: MatchSearchType.rated,
      );

      expect(result['queueId'], 'q1');
    });

    test('submitMove records move payload', () async {
      await repository.submitMove(
        gameId: 'g1',
        from: 'e2',
        to: 'e4',
        san: 'e4',
        expectedVersion: 3,
      );

      expect(remote.submittedMoves, hasLength(1));
      expect(remote.submittedMoves.first['from'], 'e2');
      expect(remote.submittedMoves.first['expectedVersion'], 3);
    });

    test('watchActiveGameId streams reconnect target', () async {
      remote.activeGameId = 'resume-game-42';

      final id = await repository.watchActiveGameId('user-1').first;

      expect(id, 'resume-game-42');
    });

    test('createPrivateMatch returns invite', () async {
      final invite = await repository.createPrivateMatch(
        mode: 'casual',
        timeControl: '5+0',
      );

      expect(invite.inviteCode, 'ABC123');
      expect(invite.timeControl, '5+0');
    });
  });
}
