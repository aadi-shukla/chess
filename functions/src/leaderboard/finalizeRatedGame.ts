import * as admin from "firebase-admin";
import { db, COLLECTIONS } from "../utils/db";
import { syncLeaderboardEntries } from "./sync";

const K_FACTOR = 32;

type GameResult = "white_wins" | "black_wins" | "draw";

function expectedScore(playerRating: number, opponentRating: number): number {
  return 1 / (1 + Math.pow(10, (opponentRating - playerRating) / 400));
}

function calculateElo(
  playerRating: number,
  opponentRating: number,
  score: number,
): number {
  const expected = expectedScore(playerRating, opponentRating);
  return Math.round(playerRating + K_FACTOR * (score - expected));
}

function scoresForResult(result: GameResult): { white: number; black: number } {
  if (result === "white_wins") return { white: 1, black: 0 };
  if (result === "black_wins") return { white: 0, black: 1 };
  return { white: 0.5, black: 0.5 };
}

/**
 * Atomically applies Elo + stats when a rated game has finished.
 * Idempotent — no-op if ratings were already applied or result mismatches.
 */
export async function finalizeRatedGame(
  gameId: string,
  expectedResult: GameResult,
): Promise<void> {
  const gameRef = db.collection(COLLECTIONS.games).doc(gameId);

  const syncPayload = await db.runTransaction(async (transaction) => {
    const gameSnap = await transaction.get(gameRef);
    if (!gameSnap.exists) return null;

    const game = gameSnap.data()!;
    if (game.mode !== "rated") return null;
    if (game.ratingApplied === true) return null;
    if (game.status !== "finished") return null;
    if (game.result !== expectedResult) return null;

    const whiteUid = game.whiteUid as string;
    const blackUid = game.blackUid as string;
    const whiteRef = db.collection(COLLECTIONS.users).doc(whiteUid);
    const blackRef = db.collection(COLLECTIONS.users).doc(blackUid);

    const [whiteSnap, blackSnap] = await Promise.all([
      transaction.get(whiteRef),
      transaction.get(blackRef),
    ]);

    const whiteData = whiteSnap.data() ?? {};
    const blackData = blackSnap.data() ?? {};
    const whiteRating = (whiteData.rating as number) ?? 1200;
    const blackRating = (blackData.rating as number) ?? 1200;

    const { white: whiteScore, black: blackScore } =
      scoresForResult(expectedResult);
    const newWhiteRating = calculateElo(whiteRating, blackRating, whiteScore);
    const newBlackRating = calculateElo(blackRating, whiteRating, blackScore);
    const now = admin.firestore.FieldValue.serverTimestamp();

    transaction.update(gameRef, {
      ratingApplied: true,
      updatedAt: now,
    });

    transaction.update(whiteRef, {
      rating: newWhiteRating,
      "stats.played": admin.firestore.FieldValue.increment(1),
      "stats.wins": admin.firestore.FieldValue.increment(whiteScore === 1 ? 1 : 0),
      "stats.losses": admin.firestore.FieldValue.increment(whiteScore === 0 ? 1 : 0),
      "stats.draws": admin.firestore.FieldValue.increment(whiteScore === 0.5 ? 1 : 0),
      updatedAt: now,
    });

    transaction.update(blackRef, {
      rating: newBlackRating,
      "stats.played": admin.firestore.FieldValue.increment(1),
      "stats.wins": admin.firestore.FieldValue.increment(blackScore === 1 ? 1 : 0),
      "stats.losses": admin.firestore.FieldValue.increment(blackScore === 0 ? 1 : 0),
      "stats.draws": admin.firestore.FieldValue.increment(blackScore === 0.5 ? 1 : 0),
      updatedAt: now,
    });

    const whiteStats = whiteData.stats as Record<string, number> | undefined;
    const blackStats = blackData.stats as Record<string, number> | undefined;

    return {
      white: {
        uid: whiteUid,
        displayName: (whiteData.displayName as string) ?? "Player",
        photoUrl: (whiteData.photoUrl as string | null) ?? null,
        rating: newWhiteRating,
        wins: (whiteStats?.wins as number ?? 0) + (whiteScore === 1 ? 1 : 0),
        played: (whiteStats?.played as number ?? 0) + 1,
      },
      black: {
        uid: blackUid,
        displayName: (blackData.displayName as string) ?? "Player",
        photoUrl: (blackData.photoUrl as string | null) ?? null,
        rating: newBlackRating,
        wins: (blackStats?.wins as number ?? 0) + (blackScore === 1 ? 1 : 0),
        played: (blackStats?.played as number ?? 0) + 1,
      },
      result: expectedResult,
      whiteUid,
      blackUid,
    };
  });

  if (!syncPayload) return;

  await syncLeaderboardEntries(
    syncPayload.white,
    syncPayload.black,
    {
      whiteUid: syncPayload.whiteUid,
      blackUid: syncPayload.blackUid,
      result: syncPayload.result,
    },
  );
}
