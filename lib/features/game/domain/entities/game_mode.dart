/// Offline game mode.
enum GameMode {
  playerVsPlayer,
  playerVsAi;

  String get label => switch (this) {
        GameMode.playerVsPlayer => 'Player vs Player',
        GameMode.playerVsAi => 'Player vs AI',
      };
}
