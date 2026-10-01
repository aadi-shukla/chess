import * as admin from "firebase-admin";
import { parseTimeControl } from "../game/chess_engine";
import { db, COLLECTIONS } from "../utils/db";
import { GameMode } from "./types";

const STARTING_FEN =
  "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

export interface CreateGameParams {
  whiteUid: string;
  blackUid: string;
  mode: GameMode;
  timeControl: string;
}

/**
 * Creates an online game and sets activeGameId on both players atomically.
 */
export async function createOnlineGame(
  params: CreateGameParams,
): Promise<string> {
  const gameId = db.collection(COLLECTIONS.games).doc().id;
  const gameRef = db.collection(COLLECTIONS.games).doc(gameId);
  const startedAt = admin.firestore.Timestamp.now();
  const { minutes, incrementSeconds } = parseTimeControl(params.timeControl);
  const startingMillis = minutes * 60 * 1000;
  const serverNow = admin.firestore.FieldValue.serverTimestamp();

  await db.runTransaction(async (transaction) => {
    const whiteRef = db.collection(COLLECTIONS.users).doc(params.whiteUid);
    const blackRef = db.collection(COLLECTIONS.users).doc(params.blackUid);
    const [whiteSnap, blackSnap] = await Promise.all([
      transaction.get(whiteRef),
      transaction.get(blackRef),
    ]);

    if (!whiteSnap.exists || !blackSnap.exists) {
      throw new Error("Player profile not found.");
    }

    if (whiteSnap.data()?.activeGameId || blackSnap.data()?.activeGameId) {
      throw new Error("Player already in an active game.");
    }

    transaction.set(gameRef, {
      whiteUid: params.whiteUid,
      blackUid: params.blackUid,
      status: "active",
      fen: STARTING_FEN,
      turn: "white",
      moveHistory: [],
      version: 1,
      timeControl: params.timeControl,
      mode: params.mode,
      whiteMillis: startingMillis,
      blackMillis: startingMillis,
      incrementMillis: incrementSeconds * 1000,
      lastMoveAt: startedAt,
      drawOffer: null,
      createdAt: startedAt,
      updatedAt: startedAt,
    });

    transaction.update(whiteRef, { activeGameId: gameId, updatedAt: serverNow });
    transaction.update(blackRef, { activeGameId: gameId, updatedAt: serverNow });
  });

  return gameId;
}
