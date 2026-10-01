# Online Multiplayer (Phase 8)

Realtime online chess via Firestore game rooms and Cloud Functions.

## Architecture

```
Flutter client                    Cloud Functions                 Firestore
─────────────                    ───────────────                 ─────────
MatchmakingPage  ──callable──►  joinMatchmakingQueue            matchmaking/
OnlineGamePage   ◄──snapshot──   submitMove (chess.js)           games/{gameId}
                 ──callable──►  resignGame / offerDraw          users/{uid}.activeGameId
```

- **Client writes to `games/` are denied** — all mutations go through callables.
- **Client pre-validates** moves with the local engine; the server is the source of truth.
- **`expectedVersion`** on `submitMove` provides optimistic concurrency / conflict handling.

## Game document (`games/{gameId}`)

| Field | Description |
|-------|-------------|
| `whiteUid`, `blackUid` | Participants |
| `fen`, `turn`, `version` | Position + turn + concurrency token |
| `moveHistory[]` | SAN, from/to, promotion, `byUid` |
| `whiteMillis`, `blackMillis`, `incrementMillis`, `lastMoveAt` | Clocks |
| `drawOffer` | `{ offeredBy, status }` or null |
| `status`, `result`, `endReason` | `active` / `finished` |
| `mode` | `casual` or `rated` |

## Cloud Functions

| Callable | Purpose |
|----------|---------|
| `joinMatchmakingQueue` | Join public queue (rated or random) |
| `pollMatchmakingQueue` | Retry pairing while waiting |
| `getQueueStatus` | Reconnect / resume queue state |
| `leaveMatchmakingQueue` | Cancel search |
| `createPrivateMatch` | Create invite room |
| `joinPrivateMatch` | Join invite room |
| `submitMove` | Validate with chess.js, update FEN, clocks, game over |
| `resignGame` | Resignation result |
| `offerDraw` / `respondToDraw` | Draw negotiation |
| `claimTimeout` | Win on flag fall |
| `claimTimeout` | Claim opponent timeout (server-validated clocks) |

Rated games auto-apply Elo via `finalizeRatedGame` when a game ends.

## Flutter feature (`lib/features/online/`)

- `OnlineGameRepository` — Firestore snapshots + callables
- `MatchmakingController` / `OnlineGameController` — UI state
- `ChessBoardHost` — shared board contract with offline play

## Reconnect / resume

1. `users/{uid}.activeGameId` set while in an active game.
2. Splash loads profile and navigates to `/online/game/:gameId` when set.
3. `OnlineGameController` re-subscribes to the game snapshot on reconnect.
4. Version conflicts on move submit trigger a fresh sync from the server.

## Security

- Firestore rules: `games/{gameId}` read for participants only, write `false`.
- Functions verify auth + participant on every action.
- Illegal moves rejected server-side with chess.js.

## Testing

```bash
flutter test test/unit/online/
cd functions && npm test   # if configured
```

## Deploy

```bash
firebase deploy --only functions,firestore:rules,firestore:indexes
```

Ensure `flutterfire configure` has been run so the client can reach your project.
