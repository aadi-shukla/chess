import 'package:chess/chess_engine/chess_engine.dart';
import 'package:chess/features/game/domain/entities/board_theme.dart';
import 'package:chess/features/game/domain/entities/game_mode.dart';

/// Configuration passed when starting an offline game.
class GameConfig {
  const GameConfig({
    this.mode = GameMode.playerVsPlayer,
    this.minutes = 10,
    this.incrementSeconds = 0,
    this.aiDifficulty = AiDifficulty.medium,
    this.humanColor = ChessColor.white,
    this.boardTheme = BoardTheme.classic,
  });

  final GameMode mode;
  final int minutes;
  final int incrementSeconds;
  final AiDifficulty aiDifficulty;
  final ChessColor humanColor;
  final BoardTheme boardTheme;

  bool get isVsAi => mode == GameMode.playerVsAi;
}
