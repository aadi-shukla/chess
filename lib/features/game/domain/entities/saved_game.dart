import 'package:chess/chess_engine/chess_engine.dart';
import 'package:chess/features/game/domain/entities/game_mode.dart';

/// Persisted in-progress offline game.
class SavedGame {
  const SavedGame({
    required this.id,
    required this.mode,
    required this.snapshot,
    required this.savedAt,
    required this.aiDifficulty,
    required this.humanColor,
    this.moveCount = 0,
    this.syncVersion = 0,
    this.updatedAtMillis = 0,
    this.deleted = false,
  });

  factory SavedGame.fromJson(Map<String, dynamic> json) {
    return SavedGame(
      id: json['id'] as String,
      mode: GameMode.values.byName(json['mode'] as String),
      snapshot: ChessGameSnapshot.fromJson(
        Map<String, dynamic>.from(json['snapshot'] as Map),
      ),
      savedAt: DateTime.parse(json['savedAt'] as String),
      aiDifficulty: AiDifficulty.values.byName(json['aiDifficulty'] as String),
      humanColor: ChessColor.values.byName(json['humanColor'] as String),
      moveCount: json['moveCount'] as int? ?? 0,
      syncVersion: json['syncVersion'] as int? ?? 0,
      updatedAtMillis: json['updatedAtMillis'] as int? ?? 0,
      deleted: json['deleted'] as bool? ?? false,
    );
  }

  factory SavedGame.fromCloudJson(Map<String, dynamic> json) {
    return SavedGame.fromJson(json);
  }

  final String id;
  final GameMode mode;
  final ChessGameSnapshot snapshot;
  final DateTime savedAt;
  final AiDifficulty aiDifficulty;
  final ChessColor humanColor;
  final int moveCount;
  final int syncVersion;
  final int updatedAtMillis;
  final bool deleted;

  Map<String, dynamic> toJson() => {
        'id': id,
        'mode': mode.name,
        'snapshot': snapshot.toJson(),
        'savedAt': savedAt.toIso8601String(),
        'aiDifficulty': aiDifficulty.name,
        'humanColor': humanColor.name,
        'moveCount': moveCount,
        'syncVersion': syncVersion,
        'updatedAtMillis': updatedAtMillis,
        'deleted': deleted,
      };

  SavedGame bumpVersion() {
    return SavedGame(
      id: id,
      mode: mode,
      snapshot: snapshot,
      savedAt: savedAt,
      aiDifficulty: aiDifficulty,
      humanColor: humanColor,
      moveCount: moveCount,
      syncVersion: syncVersion + 1,
      updatedAtMillis: DateTime.now().millisecondsSinceEpoch,
      deleted: deleted,
    );
  }

  /// Firestore document payload for `users/{uid}/games/{id}`.
  Map<String, dynamic> toCloudJson({required String ownerUid}) => {
        'id': id,
        'ownerUid': ownerUid,
        'type': 'offline',
        'status': deleted ? 'deleted' : 'in_progress',
        'mode': mode.name,
        'aiDifficulty': aiDifficulty.name,
        'humanColor': humanColor.name,
        'moveCount': moveCount,
        'snapshot': snapshot.toJson(),
        'savedAt': savedAt.toIso8601String(),
        'syncVersion': syncVersion,
        'updatedAtMillis': updatedAtMillis,
        'deleted': deleted,
      };
}
