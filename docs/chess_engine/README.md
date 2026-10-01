# Chess Engine

Pure Dart chess engine used for offline play. No Flutter or Firebase dependencies.

## Architecture

```
lib/chess_engine/
├── chess_engine.dart          # Public barrel export
└── src/
    ├── square.dart            # a1–h8 board indexing
    ├── piece.dart             # Piece, PieceType, ChessColor
    ├── move.dart              # ChessMove + special-move flags
    ├── position.dart          # Immutable board state
    ├── castling_rights.dart   # FEN castling serialization
    ├── attack_detector.dart   # Attacks, check detection
    ├── move_generator.dart    # Pseudo-legal + legal move generation
    ├── move_executor.dart     # Apply moves (copy-on-write)
    ├── game_status.dart       # Checkmate, stalemate, draws
    ├── chess_game.dart        # Session: undo/redo, history, perft
    ├── notation/
    │   ├── fen.dart           # FEN parse/serialize
    │   ├── san.dart           # Standard Algebraic Notation
    │   └── pgn.dart           # Portable Game Notation export
    └── timer/
        └── chess_clock.dart   # Side clocks with increment
```

### Design principles

- **Immutable positions** — `MoveExecutor.apply` returns a new `Position`; nothing mutates in place.
- **Legal move filter** — generate pseudo-legal moves, apply each, reject if own king is in check.
- **Separation** — engine is UI-agnostic; Flutter presentation lives in `lib/features/game/`.

## Rules implemented

| Rule | Module |
|------|--------|
| Piece movement | `move_generator.dart` |
| Check / checkmate / stalemate | `attack_detector.dart`, `game_status.dart` |
| Castling | `move_generator.dart`, `move_executor.dart` |
| Pawn promotion (Q/R/B/N) | `move_generator.dart`, `move_executor.dart` |
| En passant | `move_generator.dart`, `move_executor.dart` |
| Fifty-move rule | `game_status.dart` |
| Threefold repetition | `chess_game.dart` + `position.repetitionKey` |
| Insufficient material | `game_status.dart` |
| Undo / redo | `chess_game.dart` |
| Move history / SAN | `chess_game.dart`, `san.dart` |
| PGN export | `pgn.dart` |
| FEN import/export | `fen.dart` |
| Chess clock | `chess_clock.dart` |

## Usage

```dart
import 'package:chess/chess_engine/chess_engine.dart';

final game = ChessGame(
  initialClock: ChessClock(
    whiteMillis: 600_000,
    blackMillis: 600_000,
    incrementMillis: 3_000,
  ),
);

game.makeMoveFromUci('e2e4');
game.makeMoveFromUci('e7e5');

print(game.fen);
print(game.exportPgn());

game.undo();
```

### Perft validation

```bash
dart run tool/perft_suite.dart
flutter test test/unit/chess_engine/
```

Reference positions match [Chess Programming Wiki Perft Results](https://www.chessprogramming.org/Perft_Results).

## Offline UI

Flutter presentation:

- `lib/features/game/presentation/controllers/offline_game_controller.dart` — GetX controller wrapping `ChessGame`
- `lib/features/game/presentation/pages/offline_game_page.dart` — board, clocks, history
- `lib/features/game/presentation/widgets/chess_board_widget.dart` — interactive board with animations

Navigate from **Play → Local game** or route `/game/offline`.

## Performance

- Move generation iterates 64 squares; suitable for interactive play and perft to depth 4–5 on device.
- No bitboards yet — optimize if AI search is added in a later phase.

## Testing

`test/unit/chess_engine/perft_test.dart` covers:

- Perft (start, Kiwipete, promotion, en passant positions)
- FEN round-trip
- Special moves (castle, en passant, promotion)
- Game outcomes (checkmate, stalemate, fifty-move)
- Undo/redo, PGN export, clock

## Not in scope (Phase 5)

- Online multiplayer / Firebase move sync
- Chess960

## AI (Phase 6)

`lib/chess_engine/src/ai/chess_ai.dart` — minimax with alpha-beta pruning and five difficulty presets. See [`docs/game/README.md`](../../docs/game/README.md).
