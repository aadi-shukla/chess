import 'package:chess/features/game/domain/entities/game_mode.dart';

/// Completed offline game record for history sync.
class GameHistoryEntry {
  const GameHistoryEntry({
    required this.id,
    required this.mode,
    required this.result,
    required this.moveCount,
    required this.completedAt,
    this.moveSans = const [],
    this.syncVersion = 0,
  });

  factory GameHistoryEntry.fromJson(Map<String, dynamic> json) {
    return GameHistoryEntry(
      id: json['id'] as String,
      mode: GameMode.values.byName(json['mode'] as String),
      result: json['result'] as String,
      moveCount: json['moveCount'] as int? ?? 0,
      completedAt: DateTime.parse(json['completedAt'] as String),
      moveSans: (json['moveSans'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      syncVersion: json['syncVersion'] as int? ?? 0,
    );
  }

  final String id;
  final GameMode mode;
  final String result;
  final int moveCount;
  final DateTime completedAt;
  final List<String> moveSans;
  final int syncVersion;

  Map<String, dynamic> toJson() => {
        'id': id,
        'mode': mode.name,
        'result': result,
        'moveCount': moveCount,
        'completedAt': completedAt.toIso8601String(),
        'moveSans': moveSans,
        'syncVersion': syncVersion,
      };

  GameHistoryEntry bumpVersion() {
    return GameHistoryEntry(
      id: id,
      mode: mode,
      result: result,
      moveCount: moveCount,
      completedAt: completedAt,
      moveSans: moveSans,
      syncVersion: syncVersion + 1,
    );
  }
}
