import { onCall, HttpsError } from "firebase-functions/v2/https";
import { db, COLLECTIONS } from "../utils/db";
import { getBoardId, LeaderboardScope } from "./periods";

const MAX_PAGE_SIZE = 50;
const DEFAULT_PAGE_SIZE = 25;

interface LeaderboardCursor {
  uid: string;
  rating?: number;
  wins?: number;
  displayNameLower?: string;
  startRank?: number;
}

interface GetLeaderboardRequest {
  scope?: LeaderboardScope;
  sortBy?: "rating" | "wins";
  pageSize?: number;
  cursor?: LeaderboardCursor;
  searchQuery?: string;
}

interface LeaderboardRow {
  uid: string;
  displayName: string;
  photoUrl: string | null;
  rating: number;
  wins: number;
  played: number;
  rank: number;
}

function parseScope(value: unknown): LeaderboardScope {
  if (value === "weekly" || value === "monthly") return value;
  return "global";
}

function parseSortBy(value: unknown): "rating" | "wins" {
  return value === "wins" ? "wins" : "rating";
}

/**
 * Callable: paginated leaderboard with optional name-prefix search.
 */
export const getLeaderboard = onCall(async (request) => {
  const data = (request.data ?? {}) as GetLeaderboardRequest;
  const scope = parseScope(data.scope);
  const sortBy = parseSortBy(data.sortBy);
  const pageSize = Math.min(
    MAX_PAGE_SIZE,
    Math.max(1, data.pageSize ?? DEFAULT_PAGE_SIZE),
  );
  const boardId = getBoardId(scope);
  const search = (data.searchQuery?.trim().toLowerCase() ?? "").slice(0, 32);
  const startRank = data.cursor?.startRank ?? 1;

  let query: FirebaseFirestore.Query = db
    .collection(COLLECTIONS.leaderboards)
    .doc(boardId)
    .collection("entries");

  if (search.length > 0) {
    if (search.length < 2) {
      throw new HttpsError(
        "invalid-argument",
        "Search query must be at least 2 characters.",
      );
    }
    query = query
      .where("displayNameLower", ">=", search)
      .where("displayNameLower", "<=", `${search}\uf8ff`)
      .orderBy("displayNameLower")
      .orderBy("uid");

    if (data.cursor?.displayNameLower != null) {
      query = query.startAfter(
        data.cursor.displayNameLower,
        data.cursor.uid,
      );
    }
  } else {
    query = query.orderBy(sortBy, "desc").orderBy("uid");

    if (data.cursor?.uid) {
      const primary =
        sortBy === "wins" ? data.cursor.wins : data.cursor.rating;
      if (primary == null) {
        throw new HttpsError("invalid-argument", "Invalid pagination cursor.");
      }
      query = query.startAfter(primary, data.cursor.uid);
    }
  }

  const snapshot = await query.limit(pageSize + 1).get();
  const docs = snapshot.docs.slice(0, pageSize);
  const hasMore = snapshot.docs.length > pageSize;

  const entries: LeaderboardRow[] = docs.map((doc, index) => {
    const row = doc.data();
    return {
      uid: row.uid as string,
      displayName: row.displayName as string,
      photoUrl: (row.photoUrl as string | null) ?? null,
      rating: (row.rating as number) ?? 0,
      wins: (row.wins as number) ?? 0,
      played: (row.played as number) ?? 0,
      rank: startRank + index,
    };
  });

  const lastDoc = docs[docs.length - 1];
  let nextCursor: LeaderboardCursor | null = null;
  if (hasMore && lastDoc) {
    const lastData = lastDoc.data();
    nextCursor = {
      uid: lastData.uid as string,
      rating: lastData.rating as number,
      wins: lastData.wins as number,
      displayNameLower: lastData.displayNameLower as string,
      startRank: startRank + docs.length,
    };
  }

  return {
    boardId,
    scope,
    sortBy: search.length > 0 ? "name" : sortBy,
    entries,
    hasMore,
    nextCursor,
  };
});
