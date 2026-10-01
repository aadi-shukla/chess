# Offline Gameplay (Phase 6)

Local chess with PvP, PvAI, persistence, statistics, and configurable settings.

## Features

| Feature | Location |
|---------|----------|
| Player vs Player | Play → Local game → setup → game |
| Player vs AI | Play → Play vs AI → difficulty + color |
| Difficulty levels | Beginner (depth 1 + random), Easy–Expert (depth 2–5) |
| Hive save / resume | Auto-save after each move; resume card on Play tab |
| Statistics | Play → Statistics; PvP and PvAI win/loss/draw |
| Board themes | Classic, Forest, Ocean, Midnight |
| Settings | Settings → Offline game section |

## Architecture

```
lib/features/game/
├── domain/
│   ├── entities/          # GameConfig, SavedGame, GameStatistics, BoardTheme
│   └── repositories/      # GameRepository interface
├── data/
│   └── repositories/      # GameRepositoryImpl + GameLocalDataSource (Hive)
└── presentation/
    ├── controllers/       # OfflineGameController, PlayTabController, GameSettingsController
    ├── pages/             # GameSetupPage, OfflineGamePage, GameStatisticsPage
    └── widgets/           # Board, clocks, PlayTab, etc.

lib/chess_engine/src/ai/
└── chess_ai.dart          # Minimax + alpha-beta AI
```

## Routes

| Route | Screen |
|-------|--------|
| `/game/setup` | Pre-game options (time, AI, theme) |
| `/game/offline` | Active game board |
| `/game/statistics` | Offline stats |

## Hive keys (`game` box)

- `saved_game` — JSON snapshot of in-progress game
- `game_stats` — win/loss/draw counters
- `board_theme`, `default_minutes`, `default_increment`, `default_ai_difficulty`
- `haptics_enabled`, `auto_save_enabled`

## AI

`ChessAi.findBestMove(position, side, difficulty: …)` uses material + mobility evaluation with alpha-beta search. Beginner adds random moves for easier play.

## Testing

```bash
flutter test test/unit/chess_engine/chess_ai_test.dart
flutter test test/unit/game/
```

## Not in scope

- Online multiplayer
- Opening book / tablebases
- Chess960
