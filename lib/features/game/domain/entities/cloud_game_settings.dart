import 'package:chess/chess_engine/chess_engine.dart';
import 'package:chess/features/game/domain/entities/board_theme.dart';
import 'package:chess/features/game/domain/entities/game_statistics.dart';

/// Game preferences and statistics bundle for cloud sync.
class CloudGameSettings {
  const CloudGameSettings({
    this.boardTheme = BoardTheme.classic,
    this.defaultMinutes = 10,
    this.defaultIncrement = 0,
    this.defaultAiDifficulty = AiDifficulty.medium,
    this.hapticsEnabled = true,
    this.autoSaveEnabled = true,
    this.statistics = const GameStatistics(),
    this.syncVersion = 0,
    this.updatedAtMillis = 0,
  });

  factory CloudGameSettings.fromJson(Map<String, dynamic> json) {
    return CloudGameSettings(
      boardTheme: BoardTheme.values.byName(
        json['boardTheme'] as String? ?? BoardTheme.classic.name,
      ),
      defaultMinutes: json['defaultMinutes'] as int? ?? 10,
      defaultIncrement: json['defaultIncrement'] as int? ?? 0,
      defaultAiDifficulty: AiDifficulty.values.byName(
        json['defaultAiDifficulty'] as String? ?? AiDifficulty.medium.name,
      ),
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
      autoSaveEnabled: json['autoSaveEnabled'] as bool? ?? true,
      statistics: json['statistics'] is Map
          ? GameStatistics.fromJson(
              Map<String, dynamic>.from(json['statistics'] as Map),
            )
          : const GameStatistics(),
      syncVersion: json['syncVersion'] as int? ?? 0,
      updatedAtMillis: json['updatedAtMillis'] as int? ?? 0,
    );
  }

  final BoardTheme boardTheme;
  final int defaultMinutes;
  final int defaultIncrement;
  final AiDifficulty defaultAiDifficulty;
  final bool hapticsEnabled;
  final bool autoSaveEnabled;
  final GameStatistics statistics;
  final int syncVersion;
  final int updatedAtMillis;

  Map<String, dynamic> toJson() => {
        'boardTheme': boardTheme.name,
        'defaultMinutes': defaultMinutes,
        'defaultIncrement': defaultIncrement,
        'defaultAiDifficulty': defaultAiDifficulty.name,
        'hapticsEnabled': hapticsEnabled,
        'autoSaveEnabled': autoSaveEnabled,
        'statistics': statistics.toJson(),
        'syncVersion': syncVersion,
        'updatedAtMillis': updatedAtMillis,
      };

  CloudGameSettings copyWith({
    BoardTheme? boardTheme,
    int? defaultMinutes,
    int? defaultIncrement,
    AiDifficulty? defaultAiDifficulty,
    bool? hapticsEnabled,
    bool? autoSaveEnabled,
    GameStatistics? statistics,
    int? syncVersion,
    int? updatedAtMillis,
  }) {
    return CloudGameSettings(
      boardTheme: boardTheme ?? this.boardTheme,
      defaultMinutes: defaultMinutes ?? this.defaultMinutes,
      defaultIncrement: defaultIncrement ?? this.defaultIncrement,
      defaultAiDifficulty: defaultAiDifficulty ?? this.defaultAiDifficulty,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      autoSaveEnabled: autoSaveEnabled ?? this.autoSaveEnabled,
      statistics: statistics ?? this.statistics,
      syncVersion: syncVersion ?? this.syncVersion,
      updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
    );
  }

  CloudGameSettings bumpVersion() {
    return CloudGameSettings(
      boardTheme: boardTheme,
      defaultMinutes: defaultMinutes,
      defaultIncrement: defaultIncrement,
      defaultAiDifficulty: defaultAiDifficulty,
      hapticsEnabled: hapticsEnabled,
      autoSaveEnabled: autoSaveEnabled,
      statistics: statistics,
      syncVersion: syncVersion + 1,
      updatedAtMillis: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
