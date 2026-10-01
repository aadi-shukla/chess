# Leaderboards (Phase 10)

Ranked player standings with global, weekly, and monthly boards.

## Boards

| Scope | Board ID | Resets |
|-------|----------|--------|
| Global | `global` | Never |
| Weekly | `weekly-YYYY-Www` | ISO week (UTC) |
| Monthly | `monthly-YYYY-MM` | Calendar month (UTC) |

## Sort metrics

| Metric | Field | Description |
|--------|-------|-------------|
| Highest rating | `rating` DESC | Global = current Elo; weekly/monthly = peak rating in period |
| Most wins | `wins` DESC | Global = lifetime wins; weekly/monthly = wins in period |

## Firestore schema

`leaderboards/{boardId}/entries/{uid}`

```typescript
{
  uid: string,
  displayName: string,
  displayNameLower: string,  // prefix search
  photoUrl: string | null,
  rating: number,
  wins: number,
  played: number,
  updatedAt: Timestamp,
}
```

## Cloud Functions

| Callable | Purpose |
|----------|---------|
| `getLeaderboard` | Paginated fetch + search (max 50/page) |

### Sync (automatic)

`syncLeaderboardEntries` runs after every rated game via `finalizeRatedGame`, updating global + current weekly + current monthly boards.

New users get a global entry from `onAuthUserCreate`.

## Pagination

Client passes `cursor` from previous response:

```json
{ "uid": "...", "rating": 1500, "startRank": 26 }
```

Ranks are computed as `startRank + index` — no expensive count queries.

## Search

Prefix match on `displayNameLower` (min 2 characters). Switches to name sort while searching.

## Security

- **Read**: public (`allow read: if true` on entries)
- **Write**: Functions only (`allow write: if false`)
- `getLeaderboard` caps page size at 50 server-side

## Indexes (`firestore.indexes.json`)

- `rating DESC, uid ASC`
- `wins DESC, uid ASC`
- `displayNameLower ASC, uid ASC`

Collection group: `entries` (applies to all boards).

## Flutter

- `LeaderboardTab` on home nav (index 2)
- Scope: Global / Weekly / Monthly
- Metric: Rating / Wins
- Pull-to-refresh, infinite scroll, highlights current user

## Testing

```bash
cd functions && npm test   # period key tests
flutter test test/unit/leaderboard/
```

## Deploy

```bash
firebase deploy --only functions,firestore:rules,firestore:indexes
```
