import 'package:chess/core/firebase/firestore_paths.dart';
import 'package:chess/core/firebase/firestore_service.dart';
import 'package:chess/core/firebase/functions_service.dart';
import 'package:chess/features/online/data/models/online_game_model.dart';
import 'package:chess/features/online/domain/entities/matchmaking.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Firestore + Cloud Functions access for online games and matchmaking.
class OnlineGameRemoteDataSource {
  OnlineGameRemoteDataSource({
    required FirestoreService firestore,
    required FunctionsService functions,
  })  : _firestore = firestore,
        _functions = functions;

  final FirestoreService _firestore;
  final FunctionsService _functions;

  Stream<OnlineGameModel?> watchGame(String gameId) {
    return _firestore
        .document(FirestorePaths.game(gameId))
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return OnlineGameModel.fromFirestore(snapshot);
    });
  }

  Future<OnlineGameModel?> getGame(String gameId) async {
    final snapshot =
        await _firestore.document(FirestorePaths.game(gameId)).get();
    if (!snapshot.exists) return null;
    return OnlineGameModel.fromFirestore(snapshot);
  }

  Stream<String?> watchActiveGameId(String uid) {
    return _firestore.document(FirestorePaths.user(uid)).snapshots().map(
      (snapshot) {
        if (!snapshot.exists) return null;
        return snapshot.data()?['activeGameId'] as String?;
      },
    );
  }

  Future<Map<String, dynamic>> joinMatchmakingQueue({
    required String mode,
    required String timeControl,
    required MatchSearchType matchType,
  }) async {
    final result = await _functions.joinMatchmakingQueue(
      mode: mode,
      timeControl: timeControl,
      matchType: matchType.value,
    );
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> pollMatchmakingQueue(String queueId) async {
    final result = await _functions.pollMatchmakingQueue(queueId: queueId);
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<QueueStatus> getQueueStatus() async {
    final result = await _functions.getQueueStatus();
    return QueueStatus.fromMap(
      Map<String, dynamic>.from(result.data as Map),
    );
  }

  Future<void> leaveMatchmakingQueue() async {
    await _functions.leaveMatchmakingQueue();
  }

  Future<MatchInvite> createPrivateMatch({
    required String mode,
    required String timeControl,
  }) async {
    final result = await _functions.createPrivateMatch(
      mode: mode,
      timeControl: timeControl,
    );
    return MatchInvite.fromMap(Map<String, dynamic>.from(result.data as Map));
  }

  Future<String> joinPrivateMatch(String inviteCode) async {
    final result = await _functions.joinPrivateMatch(inviteCode: inviteCode);
    final data = Map<String, dynamic>.from(result.data as Map);
    return data['gameId'] as String;
  }

  Stream<MatchInvite?> watchMatchInvite(String inviteCode) {
    final code = inviteCode.trim().toUpperCase();
    return _firestore
        .document(FirestorePaths.matchInvite(code))
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      final data = snapshot.data() ?? {};
      return MatchInvite(
        inviteCode: code,
        expiresAt: _timestampToDate(data['expiresAt']) ?? DateTime.now(),
        mode: data['mode'] as String? ?? 'casual',
        timeControl: data['timeControl'] as String? ?? '10+0',
        gameId: data['gameId'] as String?,
        status: data['status'] as String? ?? 'open',
      );
    });
  }

  DateTime? _timestampToDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  Future<Map<String, dynamic>> submitMove({
    required String gameId,
    required String from,
    required String to,
    required String san,
    required int expectedVersion,
    String? promotion,
  }) async {
    try {
      final result = await _functions.submitMove(
        gameId: gameId,
        from: from,
        to: to,
        san: san,
        expectedVersion: expectedVersion,
        promotion: promotion,
      );
      return Map<String, dynamic>.from(result.data as Map);
    } on FirebaseFunctionsException catch (error) {
      if (error.code == 'aborted') {
        throw const VersionConflictException();
      }
      rethrow;
    }
  }

  Future<void> resignGame(String gameId) =>
      _functions.resignGame(gameId: gameId);

  Future<void> offerDraw(String gameId) => _functions.offerDraw(gameId: gameId);

  Future<void> respondToDraw({
    required String gameId,
    required bool accept,
  }) =>
      _functions.respondToDraw(gameId: gameId, accept: accept);

  Future<void> claimTimeout({
    required String gameId,
    required String timedOutSide,
  }) =>
      _functions.claimTimeout(gameId: gameId, timedOutSide: timedOutSide);
}

/// Thrown when optimistic concurrency fails on [submitMove].
final class VersionConflictException implements Exception {
  const VersionConflictException();
}
