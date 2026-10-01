import 'package:chess/features/leaderboard/data/datasources/leaderboard_remote_datasource.dart';
import 'package:chess/features/leaderboard/data/repositories/leaderboard_repository_impl.dart';
import 'package:chess/features/leaderboard/domain/entities/leaderboard_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

void main() {
  group('LeaderboardRepositoryImpl', () {
    test('fetchPage delegates to remote datasource', () async {
      final functions = FakeFunctionsService(
        leaderboardResponse: {
          'boardId': 'global',
          'sortBy': 'rating',
          'hasMore': false,
          'entries': [
            {
              'uid': 'u1',
              'displayName': 'Alice',
              'rating': 1600,
              'wins': 10,
              'played': 15,
              'rank': 1,
            },
          ],
        },
      );

      final repository = LeaderboardRepositoryImpl(
        LeaderboardRemoteDataSource(functions),
      );

      final page = await repository.fetchPage(
        scope: LeaderboardScope.global,
        metric: LeaderboardMetric.rating,
      );

      expect(page.entries, hasLength(1));
      expect(page.entries.first.displayName, 'Alice');
      expect(page.boardId, 'global');
    });

    test('fetchPage passes search query through', () async {
      final functions = FakeFunctionsService(
        leaderboardResponse: {
          'boardId': 'global',
          'sortBy': 'rating',
          'hasMore': false,
          'entries': <Map<String, dynamic>>[],
        },
      );

      final repository = LeaderboardRepositoryImpl(
        LeaderboardRemoteDataSource(functions),
      );

      final page = await repository.fetchPage(
        scope: LeaderboardScope.weekly,
        metric: LeaderboardMetric.wins,
        searchQuery: 'alice',
      );

      expect(page.entries, isEmpty);
    });
  });
}
