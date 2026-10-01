import 'package:chess/core/firebase/firestore_paths.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Low-level Cloud Functions callable wrapper.
abstract class FunctionsService {
  Future<HttpsCallableResult<dynamic>> call(
    String name, {
    Map<String, dynamic>? parameters,
  });

  Future<HttpsCallableResult<dynamic>> joinMatchmakingQueue({
    required String mode,
    required String timeControl,
    required String matchType,
  });

  Future<HttpsCallableResult<dynamic>> pollMatchmakingQueue({
    required String queueId,
  });

  Future<HttpsCallableResult<dynamic>> getQueueStatus();

  Future<void> leaveMatchmakingQueue();

  Future<HttpsCallableResult<dynamic>> createPrivateMatch({
    required String mode,
    required String timeControl,
  });

  Future<HttpsCallableResult<dynamic>> joinPrivateMatch({
    required String inviteCode,
  });

  Future<HttpsCallableResult<dynamic>> submitMove({
    required String gameId,
    required String from,
    required String to,
    required String san,
    required int expectedVersion,
    String? promotion,
  });

  Future<void> resignGame({required String gameId});

  Future<void> offerDraw({required String gameId});

  Future<void> respondToDraw({
    required String gameId,
    required bool accept,
  });

  Future<void> claimTimeout({
    required String gameId,
    required String timedOutSide,
  });

  Future<HttpsCallableResult<dynamic>> getLeaderboard({
    required String scope,
    required String sortBy,
    int pageSize = 25,
    String? searchQuery,
    Map<String, dynamic>? cursor,
  });
}

/// Default [FunctionsService] using [FirebaseFunctions.instance].
class FunctionsServiceImpl implements FunctionsService {
  FunctionsServiceImpl({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  @override
  Future<HttpsCallableResult<dynamic>> call(
    String name, {
    Map<String, dynamic>? parameters,
  }) {
    return _functions.httpsCallable(name).call(parameters ?? {});
  }

  @override
  Future<HttpsCallableResult<dynamic>> joinMatchmakingQueue({
    required String mode,
    required String timeControl,
    required String matchType,
  }) {
    return call(
      CloudFunctionNames.joinMatchmakingQueue,
      parameters: {
        'mode': mode,
        'timeControl': timeControl,
        'matchType': matchType,
      },
    );
  }

  @override
  Future<HttpsCallableResult<dynamic>> pollMatchmakingQueue({
    required String queueId,
  }) {
    return call(
      CloudFunctionNames.pollMatchmakingQueue,
      parameters: {'queueId': queueId},
    );
  }

  @override
  Future<HttpsCallableResult<dynamic>> getQueueStatus() {
    return call(CloudFunctionNames.getQueueStatus);
  }

  @override
  Future<void> leaveMatchmakingQueue() async {
    await call(CloudFunctionNames.leaveMatchmakingQueue);
  }

  @override
  Future<HttpsCallableResult<dynamic>> createPrivateMatch({
    required String mode,
    required String timeControl,
  }) {
    return call(
      CloudFunctionNames.createPrivateMatch,
      parameters: {'mode': mode, 'timeControl': timeControl},
    );
  }

  @override
  Future<HttpsCallableResult<dynamic>> joinPrivateMatch({
    required String inviteCode,
  }) {
    return call(
      CloudFunctionNames.joinPrivateMatch,
      parameters: {'inviteCode': inviteCode},
    );
  }

  @override
  Future<HttpsCallableResult<dynamic>> submitMove({
    required String gameId,
    required String from,
    required String to,
    required String san,
    required int expectedVersion,
    String? promotion,
  }) {
    return call(
      CloudFunctionNames.submitMove,
      parameters: {
        'gameId': gameId,
        'from': from,
        'to': to,
        'san': san,
        'expectedVersion': expectedVersion,
        if (promotion != null) 'promotion': promotion,
      },
    );
  }

  @override
  Future<void> resignGame({required String gameId}) async {
    await call(CloudFunctionNames.resignGame, parameters: {'gameId': gameId});
  }

  @override
  Future<void> offerDraw({required String gameId}) async {
    await call(CloudFunctionNames.offerDraw, parameters: {'gameId': gameId});
  }

  @override
  Future<void> respondToDraw({
    required String gameId,
    required bool accept,
  }) async {
    await call(
      CloudFunctionNames.respondToDraw,
      parameters: {'gameId': gameId, 'accept': accept},
    );
  }

  @override
  Future<void> claimTimeout({
    required String gameId,
    required String timedOutSide,
  }) async {
    await call(
      CloudFunctionNames.claimTimeout,
      parameters: {'gameId': gameId, 'timedOutSide': timedOutSide},
    );
  }

  @override
  Future<HttpsCallableResult<dynamic>> getLeaderboard({
    required String scope,
    required String sortBy,
    int pageSize = 25,
    String? searchQuery,
    Map<String, dynamic>? cursor,
  }) {
    return call(
      CloudFunctionNames.getLeaderboard,
      parameters: {
        'scope': scope,
        'sortBy': sortBy,
        'pageSize': pageSize,
        if (searchQuery != null && searchQuery.isNotEmpty)
          'searchQuery': searchQuery,
        if (cursor != null) 'cursor': cursor,
      },
    );
  }
}
