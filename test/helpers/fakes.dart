import 'dart:async';

import 'package:chess/core/firebase/firestore_service.dart';
import 'package:chess/core/firebase/functions_service.dart';
import 'package:chess/core/network/connectivity_service.dart';
import 'package:chess/features/online/data/datasources/online_game_remote_datasource.dart';
import 'package:chess/features/online/data/models/online_game_model.dart';
import 'package:chess/features/online/domain/entities/matchmaking.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

/// Controllable connectivity for sync tests.
class FakeConnectivityService implements ConnectivityService {
  FakeConnectivityService({this.online = true});

  bool online;

  final _controller = StreamController<bool>.broadcast();

  @override
  bool get isOnline => online;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  void setOnline(bool value) {
    online = value;
    _controller.add(value);
  }

  void dispose() => _controller.close();
}

/// In-memory Firestore for repository and sync tests.
FirestoreService fakeFirestoreService([FakeFirebaseFirestore? firestore]) {
  return FirestoreServiceImpl(
    firestore: firestore ?? FakeFirebaseFirestore(),
  );
}

/// Stub Cloud Functions for leaderboard repository tests.
class FakeFunctionsService implements FunctionsService {
  FakeFunctionsService({this.leaderboardResponse});

  Map<String, dynamic>? leaderboardResponse;

  @override
  Future<HttpsCallableResult<dynamic>> getLeaderboard({
    required String scope,
    required String sortBy,
    int pageSize = 25,
    String? searchQuery,
    Map<String, dynamic>? cursor,
  }) async {
    return _FakeResult(leaderboardResponse ?? {});
  }

  @override
  Future<HttpsCallableResult<dynamic>> createPrivateMatch({
    required String mode,
    required String timeControl,
  }) async {
    return _FakeResult({
      'inviteCode': 'ABC123',
      'expiresAt': DateTime.now().add(const Duration(minutes: 10)).millisecondsSinceEpoch,
      'mode': mode,
      'timeControl': timeControl,
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeResult implements HttpsCallableResult<dynamic> {
  _FakeResult(this._data);

  final dynamic _data;

  @override
  dynamic get data => _data;
}

/// Spy online datasource — extends real class for repository injection.
class SpyOnlineGameRemoteDataSource extends OnlineGameRemoteDataSource {
  SpyOnlineGameRemoteDataSource()
      : super(
          firestore: fakeFirestoreService(),
          functions: FakeFunctionsService(),
        );

  OnlineGameModel? gameModel;
  String? activeGameId;
  Map<String, dynamic> joinResult = const {
    'status': 'waiting',
    'queueId': 'q1',
  };
  final List<Map<String, dynamic>> submittedMoves = [];

  @override
  Stream<OnlineGameModel?> watchGame(String gameId) {
    return Stream.value(gameModel);
  }

  @override
  Future<OnlineGameModel?> getGame(String gameId) async => gameModel;

  @override
  Stream<String?> watchActiveGameId(String uid) {
    return Stream.value(activeGameId);
  }

  @override
  Future<Map<String, dynamic>> joinMatchmakingQueue({
    required String mode,
    required String timeControl,
    required MatchSearchType matchType,
  }) async =>
      joinResult;

  @override
  Future<Map<String, dynamic>> submitMove({
    required String gameId,
    required String from,
    required String to,
    required String san,
    required int expectedVersion,
    String? promotion,
  }) async {
    submittedMoves.add({
      'gameId': gameId,
      'from': from,
      'to': to,
      'san': san,
      'expectedVersion': expectedVersion,
    });
    return {'success': true, 'version': expectedVersion + 1};
  }
}
