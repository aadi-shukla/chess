# Phase 14 — Performance & Architecture Optimization

Optimization pass across UI rebuilds, GetX, Firestore, Hive, startup, and app size.

## Summary of changes

### UI & rebuilds
- **Scoped GetX updates** — Game controllers use update IDs (`board`, `clock`, `moves`, `chrome`) so clock ticks no longer rebuild the board (~96 widgets saved × 5/sec).
- **Reactive clocks** — `whiteMillisRx` / `blackMillisRx` with `Obx` in clock widgets; timer no longer calls `update()`.
- **Board animation** — `AnimatedBuilder` drives piece tween frames; respects `AppMotion.reducedMotion`.
- **RepaintBoundary** — Clock row isolated from board repaints.
- **Home tabs** — `IndexedStack` preserves tab state (no reload on every tab switch).

### GetX
- Removed per-keystroke `update()` on matchmaking invite code input.
- Game pages use chrome-only `GetBuilder` for scaffold; board/clock/history subscribe independently.

### Firestore
- Active saved game query uses `.orderBy('updatedAtMillis').limit(1)` instead of fetching all in-progress games.
- Production cache capped at **50 MB** (was unlimited).
- Auth profile cached in memory per session; `ensureUserProfile` runs once per uid.
- Splash reconnect reads `activeGameId` from session cache (no extra Firestore read).

### Hive
- `GameLocalDataSource` caches box reference (no repeated `openBox` on every read).
- Removed duplicate `GameSettingsController.load()` from `onInit` (bootstrap loads once).

### Memory & I/O
- Offline auto-save **debounced 2 seconds** after moves (flush on `onClose`).
- Clock `AnimatedContainer` replaced with static `DecoratedBox` (no decoration animation every 200ms).

### App size
- Removed unused `freezed_annotation`, `json_annotation` runtime deps.
- Removed empty asset directory declarations from `pubspec.yaml`.

## Screen review checklist

| Screen | Optimizations applied |
|--------|----------------------|
| Splash | Session cache for reconnect routing |
| Login / Register / Forgot | Already Obx-scoped (auth) |
| Home | IndexedStack tab preservation |
| Play tab | Benefits from Hive box cache + debounced save |
| Leaderboard | Unchanged (loads on tab; kept alive in stack) |
| Profile | Kept alive in IndexedStack |
| Offline game | Scoped rebuilds + reactive clock |
| Online game | Scoped rebuilds + reactive clock |
| Matchmaking | No rebuild on invite keystroke |
| Settings | Single load at startup |
| Game setup / stats | Stateless / on-demand load |

## Measuring impact

```bash
# Run tests after optimization
flutter test

# Profile rebuilds in DevTools Performance tab while a clock is running
flutter run --profile

# Analyze app size
flutter build apk --analyze-size
```

## Future improvements (not in this pass)

- Bundle Google Fonts as assets for offline-first typography and smaller network footprint.
- Firestore `WriteBatch` for cloud sync history pushes.
- `cached_network_image` for leaderboard avatars.
- Lazy-register `CloudSyncController` after first sign-in.
- Piece sprites in `assets/pieces/` with `precacheImage` at game entry.
