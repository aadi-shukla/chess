import 'package:chess/features/leaderboard/domain/entities/leaderboard_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LeaderboardEntry', () {
    test('parses callable response row', () {
      final entry = LeaderboardEntry.fromMap({
        'uid': 'u1',
        'displayName': 'Alice',
        'photoUrl': null,
        'rating': 1450,
        'wins': 12,
        'played': 20,
        'rank': 3,
      });

      expect(entry.displayName, 'Alice');
      expect(entry.rating, 1450);
      expect(entry.rank, 3);
    });
  });

  group('LeaderboardPage', () {
    test('parses paginated response', () {
      final page = LeaderboardPage.fromMap({
        'boardId': 'global',
        'sortBy': 'rating',
        'hasMore': true,
        'entries': [
          {
            'uid': 'u1',
            'displayName': 'Alice',
            'rating': 1500,
            'wins': 5,
            'played': 8,
            'rank': 1,
          },
        ],
        'nextCursor': {'uid': 'u1', 'rating': 1500, 'startRank': 2},
      });

      expect(page.entries, hasLength(1));
      expect(page.hasMore, isTrue);
      expect(page.nextCursor?.startRank, 2);
    });
  });

  group('LeaderboardCursor', () {
    test('round-trips to map', () {
      const cursor = LeaderboardCursor(
        uid: 'abc',
        rating: 1300,
        startRank: 26,
      );

      final map = cursor.toMap();
      final parsed = LeaderboardCursor.fromMap(map);

      expect(parsed.uid, 'abc');
      expect(parsed.rating, 1300);
      expect(parsed.startRank, 26);
    });
  });
}
