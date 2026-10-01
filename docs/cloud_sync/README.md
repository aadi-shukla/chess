# Cloud Save (Phase 7)

Bidirectional sync of offline game data to Firestore per authenticated user.

## What syncs

| Data | Local (Hive) | Cloud (Firestore) |
|------|--------------|-------------------|
| In-progress game | `saved_game` | `users/{uid}/games/{gameId}` |
| Settings + statistics | `game` box keys | `users/{uid}/settings/default` |
| Completed game history | `game_history` | `users/{uid}/history/{entryId}` |

## Architecture

```
Controller (OfflineGameController, PlayTabController, CloudSyncController)
    ↓
GameRepository (local-first + cloud queue)
    ↓
GameLocalDataSource (Hive)     CloudSyncService
                                    ↓
                               GameRemoteDataSource → Firestore
```

### Key files

| File | Role |
|------|------|
| `lib/features/game/data/services/cloud_sync_service.dart` | Sync orchestration, queue, conflict resolution, retries |
| `lib/features/game/data/datasources/game_remote_datasource.dart` | Firestore CRUD |
| `lib/features/game/data/datasources/game_local_datasource.dart` | Hive + sync queue |
| `lib/features/game/presentation/controllers/cloud_sync_controller.dart` | Auto-sync on login / reconnect |
| `lib/features/game/domain/failures/sync_failure.dart` | Typed sync errors |

## Offline sync

1. All writes go to Hive immediately (local-first).
2. A `SyncQueueEntry` is enqueued in Hive (`sync_queue` key).
3. If online, `CloudSyncService.flushQueue()` pushes to Firestore.
4. On reconnect, `CloudSyncController` triggers a full sync.

## Conflict resolution

Each document carries `syncVersion` and `updatedAtMillis`:

- **Higher `syncVersion` wins** when both sides changed.
- **Tie-breaker:** `updatedAtMillis` (last-write-wins).
- **History:** merged by `id`, keeping the highest `syncVersion`.
- **Statistics:** monotonic merge via `max()` per counter when pulling settings.

## Retry logic

Failed queue items retry with exponential backoff (1s → 30s cap), up to **5 attempts** (`SyncQueueEntry.maxRetries`).

## Error handling

`Result<void>` from `syncToCloud()` with `SyncFailure` variants:

- `offline` — no network
- `not_authenticated` — no signed-in user
- `conflict` — remote data kept after divergence
- `max_retries` — queue item dropped after 5 failures

## Security

Firestore rules enforce:

- `users/{uid}/games` — owner-only; `ownerUid` must match auth uid on create
- `users/{uid}/history` — owner-only; `ownerUid` required
- `users/{uid}/settings` — owner read/write
- Top-level `games/{gameId}` — still Functions-only (online play)

Client never writes to another user's path. Protected profile fields (`rating`, `stats`) remain server-only.

## Usage

Cloud sync activates automatically when:

1. Firebase is initialized (`flutterfire configure`)
2. User is signed in
3. Device is online (or queue flushes on reconnect)

Manual sync: **Play tab → Sync button**.

## Testing

```bash
flutter test test/unit/game/
```

## Not in scope

- Real-time multiplayer game sync (uses Cloud Functions + `games/{id}`)
- Cross-device live move streaming
- End-to-end encryption of cloud saves
