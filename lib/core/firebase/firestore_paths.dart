/// Firestore collection and subcollection path constants.
abstract final class FirestorePaths {
  static const String users = 'users';
  static const String games = 'games';
  static const String matchmaking = 'matchmaking';
  static const String matchInvites = 'matchInvites';
  static const String leaderboards = 'leaderboards';

  static String user(String uid) => '$users/$uid';
  static String userSettings(String uid) => '$users/$uid/settings/default';
  static String userGame(String uid, String gameId) => '$users/$uid/games/$gameId';
  static String userHistory(String uid, String entryId) =>
      '$users/$uid/history/$entryId';
  static String game(String gameId) => '$games/$gameId';
  static String matchmakingEntry(String entryId) => '$matchmaking/$entryId';
  static String matchInvite(String code) => '$matchInvites/$code';
  static String globalLeaderboardEntry(String uid) =>
      '$leaderboards/global/entries/$uid';
}

/// Cloud Functions callable names (must match functions/src exports).
abstract final class CloudFunctionNames {
  static const String joinMatchmakingQueue = 'joinMatchmakingQueue';
  static const String pollMatchmakingQueue = 'pollMatchmakingQueue';
  static const String getQueueStatus = 'getQueueStatus';
  static const String leaveMatchmakingQueue = 'leaveMatchmakingQueue';
  static const String createPrivateMatch = 'createPrivateMatch';
  static const String joinPrivateMatch = 'joinPrivateMatch';
  static const String submitMove = 'submitMove';
  static const String resignGame = 'resignGame';
  static const String offerDraw = 'offerDraw';
  static const String respondToDraw = 'respondToDraw';
  static const String claimTimeout = 'claimTimeout';
  static const String getLeaderboard = 'getLeaderboard';
}
