/// Board color themes for offline play.
enum BoardTheme {
  classic,
  forest,
  ocean,
  midnight;

  String get label => switch (this) {
        BoardTheme.classic => 'Classic',
        BoardTheme.forest => 'Forest',
        BoardTheme.ocean => 'Ocean',
        BoardTheme.midnight => 'Midnight',
      };
}
