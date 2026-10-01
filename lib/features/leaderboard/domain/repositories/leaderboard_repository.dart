import 'package:chess/features/leaderboard/domain/entities/leaderboard_entry.dart';

/// Fetches paginated leaderboard data.
abstract class LeaderboardRepository {
  Future<LeaderboardPage> fetchPage({
    required LeaderboardScope scope,
    required LeaderboardMetric metric,
    LeaderboardCursor? cursor,
    String? searchQuery,
    int pageSize = 25,
  });
}
