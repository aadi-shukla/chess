import 'package:chess/features/online/data/datasources/online_game_remote_datasource.dart';
import 'package:chess/features/online/data/models/online_game_model.dart';
import 'package:chess/features/online/domain/entities/matchmaking.dart';
import 'package:chess/features/online/domain/entities/online_game.dart';
import 'package:chess/features/online/domain/repositories/online_game_repository.dart';

class OnlineGameRepositoryImpl implements OnlineGameRepository {
  OnlineGameRepositoryImpl(this._remote);

  final OnlineGameRemoteDataSource _remote;

  @override
  Stream<OnlineGame?> watchGame(String gameId) {
    return _remote.watchGame(gameId).map(_mapOptional);
  }

  @override
  Future<OnlineGame?> getGame(String gameId) async {
    final model = await _remote.getGame(gameId);
    return model == null ? null : OnlineGameMapper.toEntity(model);
  }

  @override
  Stream<String?> watchActiveGameId(String uid) =>
      _remote.watchActiveGameId(uid);

  @override
  Future<Map<String, dynamic>> joinMatchmakingQueue({
    required String mode,
    required String timeControl,
    required MatchSearchType matchType,
  }) =>
      _remote.joinMatchmakingQueue(
        mode: mode,
        timeControl: timeControl,
        matchType: matchType,
      );

  @override
  Future<Map<String, dynamic>> pollMatchmakingQueue(String queueId) =>
      _remote.pollMatchmakingQueue(queueId);

  @override
  Future<QueueStatus> getQueueStatus() => _remote.getQueueStatus();

  @override
  Future<void> leaveMatchmakingQueue() => _remote.leaveMatchmakingQueue();

  @override
  Future<MatchInvite> createPrivateMatch({
    required String mode,
    required String timeControl,
  }) =>
      _remote.createPrivateMatch(mode: mode, timeControl: timeControl);

  @override
  Future<String> joinPrivateMatch(String inviteCode) =>
      _remote.joinPrivateMatch(inviteCode);

  @override
  Stream<MatchInvite?> watchMatchInvite(String inviteCode) =>
      _remote.watchMatchInvite(inviteCode);

  @override
  Future<Map<String, dynamic>> submitMove({
    required String gameId,
    required String from,
    required String to,
    required String san,
    required int expectedVersion,
    String? promotion,
  }) =>
      _remote.submitMove(
        gameId: gameId,
        from: from,
        to: to,
        san: san,
        expectedVersion: expectedVersion,
        promotion: promotion,
      );

  @override
  Future<void> resignGame(String gameId) => _remote.resignGame(gameId);

  @override
  Future<void> offerDraw(String gameId) => _remote.offerDraw(gameId);

  @override
  Future<void> respondToDraw({
    required String gameId,
    required bool accept,
  }) =>
      _remote.respondToDraw(gameId: gameId, accept: accept);

  @override
  Future<void> claimTimeout({
    required String gameId,
    required String timedOutSide,
  }) =>
      _remote.claimTimeout(gameId: gameId, timedOutSide: timedOutSide);

  OnlineGame? _mapOptional(OnlineGameModel? model) {
    if (model == null) return null;
    return OnlineGameMapper.toEntity(model);
  }
}
