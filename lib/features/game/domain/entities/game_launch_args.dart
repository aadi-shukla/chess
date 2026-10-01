import 'package:chess/features/game/domain/entities/game_config.dart';
import 'package:chess/features/game/domain/entities/saved_game.dart';

/// Arguments for launching an offline game screen.
class GameLaunchArgs {
  const GameLaunchArgs({
    required this.config,
    this.resume,
  });

  final GameConfig config;
  final SavedGame? resume;
}
