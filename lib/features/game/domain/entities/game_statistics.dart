/// Offline game statistics tracked locally.
class GameStatistics {
  const GameStatistics({
    this.pvpGames = 0,
    this.pvpWhiteWins = 0,
    this.pvpBlackWins = 0,
    this.pvpDraws = 0,
    this.pvAiWins = 0,
    this.pvAiLosses = 0,
    this.pvAiDraws = 0,
  });

  factory GameStatistics.fromJson(Map<String, dynamic> json) {
    return GameStatistics(
      pvpGames: json['pvpGames'] as int? ?? 0,
      pvpWhiteWins: json['pvpWhiteWins'] as int? ?? 0,
      pvpBlackWins: json['pvpBlackWins'] as int? ?? 0,
      pvpDraws: json['pvpDraws'] as int? ?? 0,
      pvAiWins: json['pvAiWins'] as int? ?? 0,
      pvAiLosses: json['pvAiLosses'] as int? ?? 0,
      pvAiDraws: json['pvAiDraws'] as int? ?? 0,
    );
  }

  final int pvpGames;
  final int pvpWhiteWins;
  final int pvpBlackWins;
  final int pvpDraws;
  final int pvAiWins;
  final int pvAiLosses;
  final int pvAiDraws;

  int get pvAiGames => pvAiWins + pvAiLosses + pvAiDraws;

  GameStatistics copyWith({
    int? pvpGames,
    int? pvpWhiteWins,
    int? pvpBlackWins,
    int? pvpDraws,
    int? pvAiWins,
    int? pvAiLosses,
    int? pvAiDraws,
  }) {
    return GameStatistics(
      pvpGames: pvpGames ?? this.pvpGames,
      pvpWhiteWins: pvpWhiteWins ?? this.pvpWhiteWins,
      pvpBlackWins: pvpBlackWins ?? this.pvpBlackWins,
      pvpDraws: pvpDraws ?? this.pvpDraws,
      pvAiWins: pvAiWins ?? this.pvAiWins,
      pvAiLosses: pvAiLosses ?? this.pvAiLosses,
      pvAiDraws: pvAiDraws ?? this.pvAiDraws,
    );
  }

  Map<String, dynamic> toJson() => {
        'pvpGames': pvpGames,
        'pvpWhiteWins': pvpWhiteWins,
        'pvpBlackWins': pvpBlackWins,
        'pvpDraws': pvpDraws,
        'pvAiWins': pvAiWins,
        'pvAiLosses': pvAiLosses,
        'pvAiDraws': pvAiDraws,
      };
}
