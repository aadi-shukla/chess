# Security Audit (Phase 12)

Full-stack security review and remediations for authentication, Firestore, Cloud Functions, validation, anti-cheat, and rating integrity.

## Critical fixes applied

### Removed `endRatedGame` callable
**Risk:** Any participant could end an active rated game with an arbitrary result and inflate Elo.

**Fix:** Callable removed entirely. Rated games finalize only via server-trusted paths:
- `submitMove` (checkmate / draw)
- `resignGame`
- `respondToDraw` (accept)
- `claimTimeout`

All call `finalizeRatedGame` internally.

### Fixed `claimTimeout` clock validation
**Risk:** When it was the opponent's turn, a player could claim the other side lost on time without their clock running down.

**Fix:** `remainingClockMillis()` validates the **claimed side's** remaining time regardless of whose turn it is. Timeout finish runs inside a Firestore transaction with fresh clock state.

### Atomic, idempotent `finalizeRatedGame`
**Risk:** Concurrent game-end handlers could double-apply ratings (`ratingApplied` TOCTOU).

**Fix:** Single Firestore transaction:
- Requires `status === finished` and `result` matches
- Sets `ratingApplied: true` atomically
- Applies Elo + stats once

## High fixes applied

| Area | Fix |
|------|-----|
| Game end races | `resignGame` / draw accept use transactions with `status === active` guard |
| Matchmaking | `mode` + `timeControl` whitelisted on all entry points |
| Invite codes | `crypto.randomInt` instead of `Math.random` |
| Queue cleanup | Public `cleanupMatchmakingQueue` removed; scheduler only |
| Leaderboard sync | Period boards use `FieldValue.increment` for wins/played |
| Search abuse | `getLeaderboard` caps `searchQuery` at 32 chars |

## Firestore rules hardened

- User **create**: `hasOnly` allowed keys; blocks `activeGameId` / `globalRank` on create
- **matchInvites**: read restricted to host only (join via callable)
- **history**: schema validation (result enum, `moveCount` 0–500)
- **offline games**: update requires monotonic `syncVersion`, immutable `type`

## Flutter client fixes

- Session restore: no auth without live Firebase user (clears stale Hive cache)
- Auth middleware: redirects to splash while restoring
- Online game: validates `gameId` / `myUid`; shows error if not a participant
- Matchmaking: whitelisted time controls; 6-char invite code format
- Leaderboard search capped at 32 characters
- Display name character allowlist

## Architecture (defense in depth)

```
Client                    Cloud Functions              Firestore
──────                    ───────────────              ─────────
submitMove ─────────────► chess.js validate ────────► games/ (write denied)
                          finalizeRatedGame ────────► users.rating (Admin SDK)
Firestore read ◄────────  realtime snapshot ◄────── games/ (read: participants)
```

Online `games/`, `matchmaking/`, `leaderboards/` are **not client-writable**.

## Remaining recommendations (not implemented)

| Item | Priority | Notes |
|------|----------|-------|
| Firebase App Check | High | Enable on all callables in production |
| Per-UID rate limiting | High | Throttle `pollMatchmakingQueue`, `submitMove` |
| Email verification gate | Medium | Block rated queue for unverified accounts |
| Account deletion CF | Medium | Purge `users/{uid}` data on auth delete |
| Collusion detection | Medium | Min moves / pairing fraud for rated games |
| Move subcollection | Low | Avoid unbounded `moveHistory` on long games |

## Verification

```bash
# Flutter
flutter test

# Cloud Functions
cd functions && npm test

# Firestore rules (requires emulator)
cd firebase && npm test
```

## Files changed (summary)

- `functions/src/game/validateMove.ts` — transactions, clock fix
- `functions/src/leaderboard/finalizeRatedGame.ts` — atomic rating
- `functions/src/leaderboard/updateRating.ts` — **deleted** (`endRatedGame`)
- `functions/src/utils/gameValidation.ts` — shared validation
- `firestore.rules` — hardened rules
- `lib/features/auth/...` — session + validation
- `lib/features/online/...` — game + matchmaking guards
