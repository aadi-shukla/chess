# Matchmaking (Phase 9)

Server-authoritative matchmaking with public queues and private rooms.

## Modes

| Mode | Callable | Description |
|------|----------|-------------|
| **Quick match (rated)** | `joinMatchmakingQueue` | Pairs by rating with expanding ± band |
| **Quick match (random)** | `joinMatchmakingQueue` | Pairs any opponent with same mode + time control |
| **Create room** | `createPrivateMatch` | Host gets a 6-char invite code |
| **Join room** | `joinPrivateMatch` | Guest enters code to start game |
| **Cancel** | `leaveMatchmakingQueue` | Removes waiting queue entries |

## Queue lifecycle

1. Client calls `joinMatchmakingQueue` with `mode`, `timeControl`, `matchType`.
2. Server clears any existing waiting entries for the user (no duplicates).
3. Server creates `matchmaking/{queueId}` with `status: waiting`, `expiresAt`.
4. Server attempts immediate pairing; returns `{ status: matched, gameId }` or `{ status: waiting, queueId, ratingBand }`.
5. While waiting, client polls `pollMatchmakingQueue` every ~4s and listens to `users/{uid}.activeGameId`.
6. Rating band expands: ±150 → ±500 (+50 every 15s).
7. Stale entries removed by `scheduledMatchmakingCleanup` (every 2 min).

## Firestore collections

### `matchmaking/{queueId}`

| Field | Description |
|-------|-------------|
| `userId` | Player in queue |
| `rating` | Snapshot at join time |
| `mode` | `casual` \| `rated` |
| `matchType` | `rated` \| `random` |
| `timeControl` | e.g. `10+0` |
| `status` | `waiting` \| `matched` |
| `ratingBand` | Current search band |
| `expiresAt` | Auto-cleanup TTL (120s) |

### `matchInvites/{code}`

| Field | Description |
|-------|-------------|
| `hostUid` | Room creator (plays white) |
| `mode`, `timeControl` | Game settings |
| `status` | `open` \| `started` |
| `guestUid`, `gameId` | Set when guest joins |
| `expiresAt` | 15 minutes |

## Security

- **All writes** to `matchmaking/` and `matchInvites/` go through Cloud Functions only.
- Clients may **read** their own queue entry and open invites (for room codes).
- Pairing uses **Firestore transactions** to prevent double-matching.
- Validates: no active game, no self-join, invite not expired, matching time control.

## Edge cases handled

- Duplicate queue entries → cleared before re-join
- Opponent leaves queue mid-match → `aborted`, retry on poll
- Queue expiry → cleanup + client shows "Search expired"
- Mismatched time controls → only same `timeControl` paired
- Host/guest already in game → rejected
- Reconnect while waiting → `getQueueStatus` returns current state

## Cloud Functions

```
joinMatchmakingQueue   pollMatchmakingQueue   getQueueStatus
leaveMatchmakingQueue  createPrivateMatch     joinPrivateMatch
scheduledMatchmakingCleanup (cron every 2 min)
```

## Flutter UI

`MatchmakingPage` tabs:

1. **Quick match** — rated/random toggle, cancel search, live wait timer + band
2. **Create** — generate code, copy, wait for guest
3. **Join** — enter 6-char code

## Testing

```bash
cd functions && npm test    # matchEngine unit tests
flutter test test/unit/online/
```

## Deploy

```bash
firebase deploy --only functions,firestore:rules,firestore:indexes
```

Ensure composite indexes from `firestore.indexes.json` are deployed before production traffic.
