import * as admin from "firebase-admin";
import { db, COLLECTIONS } from "../utils/db";
import { getBoardId } from "./periods";

export interface LeaderboardProfile {
  uid: string;
  displayName: string;
  photoUrl: string | null;
  rating: number;
  wins: number;
  played: number;
}

export interface LeaderboardGameResult {
  whiteUid: string;
  blackUid: string;
  result: "white_wins" | "black_wins" | "draw";
}

function displayNameLower(name: string): string {
  return name.trim().toLowerCase();
}

function didWin(uid: string, result: LeaderboardGameResult): boolean {
  if (result.result === "draw") return false;
  if (result.result === "white_wins") return uid === result.whiteUid;
  return uid === result.blackUid;
}

async function upsertEntry(
  boardId: string,
  profile: LeaderboardProfile,
  won: boolean,
  isGlobal: boolean,
): Promise<void> {
  const ref = db
    .collection(COLLECTIONS.leaderboards)
    .doc(boardId)
    .collection("entries")
    .doc(profile.uid);

  const existing = await ref.get();
  const existingData = existing.data() ?? {};
  const previousRating = (existingData.rating as number) ?? profile.rating;
  const peakRating = Math.max(previousRating, profile.rating);

  const payload: Record<string, unknown> = {
    uid: profile.uid,
    displayName: profile.displayName,
    displayNameLower: displayNameLower(profile.displayName),
    photoUrl: profile.photoUrl,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (isGlobal) {
    payload.rating = profile.rating;
    payload.wins = profile.wins;
    payload.played = profile.played;
  } else {
    payload.rating = peakRating;
    payload.wins = admin.firestore.FieldValue.increment(won ? 1 : 0);
    payload.played = admin.firestore.FieldValue.increment(1);
  }

  await ref.set(payload, { merge: true });
}

/**
 * Syncs global, weekly, and monthly leaderboard entries after a rated game.
 */
export async function syncLeaderboardEntries(
  white: LeaderboardProfile,
  black: LeaderboardProfile,
  result: LeaderboardGameResult,
): Promise<void> {
  const now = new Date();
  const boards = [
    { id: getBoardId("global"), isGlobal: true },
    { id: getBoardId("weekly", now), isGlobal: false },
    { id: getBoardId("monthly", now), isGlobal: false },
  ];

  await Promise.all(
    boards.flatMap((board) => [
      upsertEntry(
        board.id,
        white,
        didWin(white.uid, result),
        board.isGlobal,
      ),
      upsertEntry(
        board.id,
        black,
        didWin(black.uid, result),
        board.isGlobal,
      ),
    ]),
  );
}

/** Creates initial global leaderboard entry for a new user. */
export async function createInitialLeaderboardEntry(
  uid: string,
  displayName: string,
  photoUrl: string | null,
  rating: number,
): Promise<void> {
  const now = admin.firestore.FieldValue.serverTimestamp();
  await db
    .collection(COLLECTIONS.leaderboards)
    .doc("global")
    .collection("entries")
    .doc(uid)
    .set({
      uid,
      displayName,
      displayNameLower: displayNameLower(displayName),
      photoUrl,
      rating,
      wins: 0,
      played: 0,
      updatedAt: now,
    });
}
