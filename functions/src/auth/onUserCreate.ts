import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";
import { db, COLLECTIONS } from "../utils/db";
import { createInitialLeaderboardEntry } from "../leaderboard/sync";

const DEFAULT_RATING = 1200;

/**
 * Creates the Firestore user profile when a new Firebase Auth user is created.
 */
export const onAuthUserCreate = functions.auth.user().onCreate(async (user) => {
  const now = admin.firestore.FieldValue.serverTimestamp();
  const displayName =
    user.displayName ?? user.email?.split("@")[0] ?? "Player";

  const profile = {
    email: user.email ?? "",
    displayName,
    photoUrl: user.photoURL ?? null,
    rating: DEFAULT_RATING,
    stats: {
      played: 0,
      wins: 0,
      losses: 0,
      draws: 0,
    },
    activeGameId: null,
    createdAt: now,
    updatedAt: now,
  };

  await db.collection(COLLECTIONS.users).doc(user.uid).set(profile);

  await createInitialLeaderboardEntry(
    user.uid,
    displayName,
    user.photoURL ?? null,
    DEFAULT_RATING,
  );

  functions.logger.info(`User profile created for ${user.uid}`);
});
