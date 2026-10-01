import 'package:chess/features/leaderboard/data/datasources/leaderboard_remote_datasource.dart';
import 'package:chess/features/leaderboard/domain/entities/leaderboard_entry.dart';
import 'package:chess/features/leaderboard/domain/repositories/leaderboard_repository.dart';

class LeaderboardRepositoryImpl implements LeaderboardRepository {
  LeaderboardRepositoryImpl(this._remote);

  final LeaderboardRemoteDataSource _remote;

  @override
  Future<LeaderboardPage> fetchPage({
    required LeaderboardScope scope,
    required LeaderboardMetric metric,
    LeaderboardCursor? cursor,
    String? searchQuery,
    int pageSize = 25,
  }) =>
      _remote.fetchPage(
        scope: scope,
        metric: metric,
        cursor: cursor,
        searchQuery: searchQuery,
        pageSize: pageSize,
      );
}
