import * as admin from "firebase-admin";

admin.initializeApp();

export const db = admin.firestore();

export const COLLECTIONS = {
  users: "users",
  games: "games",
  matchmaking: "matchmaking",
  matchInvites: "matchInvites",
  leaderboards: "leaderboards",
} as const;
