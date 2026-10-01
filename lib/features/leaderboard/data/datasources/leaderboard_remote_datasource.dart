import 'package:chess/core/firebase/functions_service.dart';
import 'package:chess/features/leaderboard/domain/entities/leaderboard_entry.dart';

/// Cloud Functions access for leaderboard queries.
class LeaderboardRemoteDataSource {
  LeaderboardRemoteDataSource(this._functions);

  final FunctionsService _functions;

  Future<LeaderboardPage> fetchPage({
    required LeaderboardScope scope,
    required LeaderboardMetric metric,
    LeaderboardCursor? cursor,
    String? searchQuery,
    int pageSize = 25,
  }) async {
    final result = await _functions.getLeaderboard(
      scope: scope.value,
      sortBy: metric.value,
      pageSize: pageSize,
      searchQuery: searchQuery,
      cursor: cursor != null && !cursor.isEmpty ? cursor.toMap() : null,
    );

    return LeaderboardPage.fromMap(
      Map<String, dynamic>.from(result.data as Map),
    );
  }
}
