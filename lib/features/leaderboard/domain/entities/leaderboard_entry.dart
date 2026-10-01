/// Leaderboard time scope.
enum LeaderboardScope {
  global,
  weekly,
  monthly;

  String get value => name;
}

/// Sort metric for leaderboard rows.
enum LeaderboardMetric {
  rating,
  wins;

  String get value => name;
}

/// Single row on a leaderboard page.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.rating,
    required this.wins,
    required this.played,
    required this.rank,
    this.photoUrl,
  });

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      uid: map['uid'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'Player',
      photoUrl: map['photoUrl'] as String?,
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      wins: (map['wins'] as num?)?.toInt() ?? 0,
      played: (map['played'] as num?)?.toInt() ?? 0,
      rank: (map['rank'] as num?)?.toInt() ?? 0,
    );
  }

  final String uid;
  final String displayName;
  final String? photoUrl;
  final int rating;
  final int wins;
  final int played;
  final int rank;
}

/// Pagination cursor returned by [getLeaderboard].
class LeaderboardCursor {
  const LeaderboardCursor({
    required this.uid,
    this.rating,
    this.wins,
    this.displayNameLower,
    this.startRank = 1,
  });

  factory LeaderboardCursor.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const LeaderboardCursor(uid: '');
    return LeaderboardCursor(
      uid: map['uid'] as String? ?? '',
      rating: (map['rating'] as num?)?.toInt(),
      wins: (map['wins'] as num?)?.toInt(),
      displayNameLower: map['displayNameLower'] as String?,
      startRank: (map['startRank'] as num?)?.toInt() ?? 1,
    );
  }

  final String uid;
  final int? rating;
  final int? wins;
  final String? displayNameLower;
  final int startRank;

  bool get isEmpty => uid.isEmpty;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      if (rating != null) 'rating': rating,
      if (wins != null) 'wins': wins,
      if (displayNameLower != null) 'displayNameLower': displayNameLower,
      'startRank': startRank,
    };
  }
}

/// Paginated leaderboard response.
class LeaderboardPage {
  const LeaderboardPage({
    required this.entries,
    required this.hasMore,
    required this.boardId,
    required this.sortBy,
    this.nextCursor,
  });

  factory LeaderboardPage.fromMap(Map<String, dynamic> map) {
    final rows = (map['entries'] as List<dynamic>? ?? [])
        .map((e) => LeaderboardEntry.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    return LeaderboardPage(
      entries: rows,
      hasMore: map['hasMore'] as bool? ?? false,
      boardId: map['boardId'] as String? ?? 'global',
      sortBy: map['sortBy'] as String? ?? 'rating',
      nextCursor: LeaderboardCursor.fromMap(
        map['nextCursor'] as Map<String, dynamic>?,
      ),
    );
  }

  final List<LeaderboardEntry> entries;
  final bool hasMore;
  final String boardId;
  final String sortBy;
  final LeaderboardCursor? nextCursor;
}
