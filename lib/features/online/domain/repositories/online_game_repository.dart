import 'package:chess/features/online/domain/entities/matchmaking.dart';
import 'package:chess/features/online/domain/entities/online_game.dart';

/// Remote operations for online multiplayer games and matchmaking.
abstract class OnlineGameRepository {
  Stream<OnlineGame?> watchGame(String gameId);

  Future<OnlineGame?> getGame(String gameId);

  Stream<String?> watchActiveGameId(String uid);

  Future<Map<String, dynamic>> joinMatchmakingQueue({
    required String mode,
    required String timeControl,
    required MatchSearchType matchType,
  });

  Future<Map<String, dynamic>> pollMatchmakingQueue(String queueId);

  Future<QueueStatus> getQueueStatus();

  Future<void> leaveMatchmakingQueue();

  Future<MatchInvite> createPrivateMatch({
    required String mode,
    required String timeControl,
  });

  Future<String> joinPrivateMatch(String inviteCode);

  Stream<MatchInvite?> watchMatchInvite(String inviteCode);

  Future<Map<String, dynamic>> submitMove({
    required String gameId,
    required String from,
    required String to,
    required String san,
    required int expectedVersion,
    String? promotion,
  });

  Future<void> resignGame(String gameId);

  Future<void> offerDraw(String gameId);

  Future<void> respondToDraw({required String gameId, required bool accept});

  Future<void> claimTimeout({
    required String gameId,
    required String timedOutSide,
  });
}
