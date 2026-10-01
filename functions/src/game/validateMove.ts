import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { finalizeRatedGame } from "../leaderboard/finalizeRatedGame";
import { remainingClockMillis } from "../utils/gameValidation";
import { db, COLLECTIONS } from "../utils/db";
import { applyMove } from "./chess_engine";

interface SubmitMoveRequest {
  gameId: string;
  from: string;
  to: string;
  promotion?: string;
  san: string;
  expectedVersion: number;
}

function assertParticipant(
  uid: string,
  whiteUid: string,
  blackUid: string,
): void {
  if (uid !== whiteUid && uid !== blackUid) {
    throw new HttpsError("permission-denied", "Not a participant.");
  }
}

function getGameOrThrow(
  game: FirebaseFirestore.DocumentData,
): {
  whiteUid: string;
  blackUid: string;
  turn: string;
  version: number;
  fen: string;
  status: string;
  mode: string;
} {
  return {
    whiteUid: game.whiteUid as string,
    blackUid: game.blackUid as string,
    turn: game.turn as string,
    version: (game.version as number) ?? 1,
    fen: (game.fen as string) ?? "",
    status: game.status as string,
    mode: game.mode as string,
  };
}

type GameResult = "white_wins" | "black_wins" | "draw";

async function finishActiveGame(
  gameId: string,
  uid: string,
  buildFinish: (
    game: FirebaseFirestore.DocumentData,
    parsed: ReturnType<typeof getGameOrThrow>,
  ) => {
    result: GameResult;
    endReason: string;
    extraUpdates?: Record<string, unknown>;
  },
): Promise<{ result: GameResult; mode: string }> {
  const gameRef = db.collection(COLLECTIONS.games).doc(gameId);

  return db.runTransaction(async (transaction) => {
    const gameSnap = await transaction.get(gameRef);

    if (!gameSnap.exists) {
      throw new HttpsError("not-found", "Game not found.");
    }

    const game = gameSnap.data()!;
    const parsed = getGameOrThrow(game);

    if (parsed.status !== "active") {
      throw new HttpsError("failed-precondition", "Game is not active.");
    }

    assertParticipant(uid, parsed.whiteUid, parsed.blackUid);

    const { result, endReason, extraUpdates } = buildFinish(game, parsed);
    const now = admin.firestore.FieldValue.serverTimestamp();

    transaction.update(gameRef, {
      status: "finished",
      result,
      endReason,
      ...extraUpdates,
      updatedAt: now,
    });
    transaction.update(db.collection(COLLECTIONS.users).doc(parsed.whiteUid), {
      activeGameId: null,
      updatedAt: now,
    });
    transaction.update(db.collection(COLLECTIONS.users).doc(parsed.blackUid), {
      activeGameId: null,
      updatedAt: now,
    });

    return { result, mode: parsed.mode };
  });
}

function elapsedSinceLastMove(
  game: FirebaseFirestore.DocumentData,
): number {
  const lastMoveAt = game.lastMoveAt as admin.firestore.Timestamp | undefined;
  const nowMs = Date.now();
  const lastMs =
    lastMoveAt?.toMillis() ??
    (game.createdAt as admin.firestore.Timestamp | undefined)?.toMillis() ??
    nowMs;
  return Math.max(0, nowMs - lastMs);
}

/**
 * Callable: validates chess rules and applies a move to an online game.
 */
export const submitMove = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  const uid = request.auth.uid;
  const data = request.data as SubmitMoveRequest;

  if (!data?.gameId || !data.from || !data.to || !data.san) {
    throw new HttpsError("invalid-argument", "Missing move fields.");
  }

  if (typeof data.expectedVersion !== "number") {
    throw new HttpsError("invalid-argument", "expectedVersion is required.");
  }

  const gameRef = db.collection(COLLECTIONS.games).doc(data.gameId);

  const result = await db.runTransaction(async (transaction) => {
    const gameSnap = await transaction.get(gameRef);

    if (!gameSnap.exists) {
      throw new HttpsError("not-found", "Game not found.");
    }

    const game = gameSnap.data()!;
    const parsed = getGameOrThrow(game);

    if (parsed.status !== "active") {
      throw new HttpsError("failed-precondition", "Game is not active.");
    }

    assertParticipant(uid, parsed.whiteUid, parsed.blackUid);

    const isWhiteTurn = parsed.turn === "white";
    if ((isWhiteTurn && uid !== parsed.whiteUid) ||
        (!isWhiteTurn && uid !== parsed.blackUid)) {
      throw new HttpsError("failed-precondition", "Not your turn.");
    }

    if (data.expectedVersion !== parsed.version) {
      throw new HttpsError(
        "aborted",
        "Version conflict — refresh and retry.",
      );
    }

    let validated;
    try {
      validated = applyMove(
        parsed.fen,
        data.from,
        data.to,
        data.promotion,
      );
    } catch {
      throw new HttpsError("invalid-argument", "Illegal move.");
    }

    const moveHistory =
      (game.moveHistory as Array<Record<string, unknown>>) ?? [];
    const now = admin.firestore.FieldValue.serverTimestamp();
    const nextTurn = isWhiteTurn ? "black" : "white";
    const nextVersion = parsed.version + 1;

    const whiteMillis = (game.whiteMillis as number) ?? 600000;
    const blackMillis = (game.blackMillis as number) ?? 600000;
    const incrementMillis = (game.incrementMillis as number) ?? 0;
    const elapsed = elapsedSinceLastMove(game);

    const updates: Record<string, unknown> = {
      fen: validated.fen,
      turn: nextTurn,
      moveHistory: [
        ...moveHistory,
        {
          san: validated.san,
          from: data.from,
          to: data.to,
          promotion: data.promotion ?? null,
          playedAt: now,
          byUid: uid,
        },
      ],
      version: nextVersion,
      updatedAt: now,
      lastMoveAt: admin.firestore.Timestamp.now(),
      drawOffer: null,
    };

    if (isWhiteTurn) {
      updates.whiteMillis = Math.max(0, whiteMillis - elapsed) + incrementMillis;
    } else {
      updates.blackMillis = Math.max(0, blackMillis - elapsed) + incrementMillis;
    }

    if (validated.isGameOver) {
      updates.status = "finished";
      updates.result = validated.result;
      updates.endReason = validated.endReason;
      transaction.update(
        db.collection(COLLECTIONS.users).doc(parsed.whiteUid),
        { activeGameId: null, updatedAt: now },
      );
      transaction.update(
        db.collection(COLLECTIONS.users).doc(parsed.blackUid),
        { activeGameId: null, updatedAt: now },
      );
    }

    transaction.update(gameRef, updates);

    return {
      success: true,
      version: nextVersion,
      turn: nextTurn,
      fen: validated.fen,
      isGameOver: validated.isGameOver,
      result: validated.result,
      mode: parsed.mode,
    };
  });

  if (result.isGameOver && result.result && result.mode === "rated") {
    await finalizeRatedGame(data.gameId, result.result);
  }

  return {
    success: result.success,
    version: result.version,
    turn: result.turn,
    fen: result.fen,
    isGameOver: result.isGameOver,
    result: result.result,
  };
});

interface GameActionRequest {
  gameId: string;
}

/**
 * Callable: resign from an active online game.
 */
export const resignGame = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  const uid = request.auth.uid;
  const data = request.data as GameActionRequest;

  if (!data?.gameId) {
    throw new HttpsError("invalid-argument", "Missing gameId.");
  }

  const finish = await finishActiveGame(
    data.gameId,
    uid,
    (_game, parsed) => ({
      result: uid === parsed.whiteUid ? "black_wins" : "white_wins",
      endReason: "resignation",
      extraUpdates: { resignedBy: uid },
    }),
  );

  if (finish.mode === "rated") {
    await finalizeRatedGame(data.gameId, finish.result);
  }

  return { success: true, result: finish.result };
});

/**
 * Callable: offer a draw in an active online game.
 */
export const offerDraw = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  const uid = request.auth.uid;
  const data = request.data as GameActionRequest;

  if (!data?.gameId) {
    throw new HttpsError("invalid-argument", "Missing gameId.");
  }

  const gameRef = db.collection(COLLECTIONS.games).doc(data.gameId);
  const gameSnap = await gameRef.get();

  if (!gameSnap.exists) {
    throw new HttpsError("not-found", "Game not found.");
  }

  const game = gameSnap.data()!;
  const parsed = getGameOrThrow(game);

  if (parsed.status !== "active") {
    throw new HttpsError("failed-precondition", "Game is not active.");
  }

  assertParticipant(uid, parsed.whiteUid, parsed.blackUid);

  await gameRef.update({
    drawOffer: { offeredBy: uid, status: "pending" },
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true };
});

interface RespondDrawRequest extends GameActionRequest {
  accept: boolean;
}

/**
 * Callable: accept or decline a draw offer.
 */
export const respondToDraw = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  const uid = request.auth.uid;
  const data = request.data as RespondDrawRequest;

  if (!data?.gameId) {
    throw new HttpsError("invalid-argument", "Missing gameId.");
  }

  if (typeof data.accept !== "boolean") {
    throw new HttpsError("invalid-argument", "accept must be a boolean.");
  }

  if (!data.accept) {
    const gameRef = db.collection(COLLECTIONS.games).doc(data.gameId);
    const gameSnap = await gameRef.get();

    if (!gameSnap.exists) {
      throw new HttpsError("not-found", "Game not found.");
    }

    const game = gameSnap.data()!;
    const parsed = getGameOrThrow(game);
    const drawOffer = game.drawOffer as { offeredBy: string; status: string } | null;

    if (parsed.status !== "active" || !drawOffer || drawOffer.status !== "pending") {
      throw new HttpsError("failed-precondition", "No pending draw offer.");
    }

    if (drawOffer.offeredBy === uid) {
      throw new HttpsError("failed-precondition", "Cannot respond to own offer.");
    }

    assertParticipant(uid, parsed.whiteUid, parsed.blackUid);

    await gameRef.update({
      drawOffer: null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { success: true, accepted: false };
  }

  const finish = await db.runTransaction(async (transaction) => {
    const gameRef = db.collection(COLLECTIONS.games).doc(data.gameId);
    const gameSnap = await transaction.get(gameRef);

    if (!gameSnap.exists) {
      throw new HttpsError("not-found", "Game not found.");
    }

    const game = gameSnap.data()!;
    const parsed = getGameOrThrow(game);
    const drawOffer = game.drawOffer as { offeredBy: string; status: string } | null;

    if (parsed.status !== "active" || !drawOffer || drawOffer.status !== "pending") {
      throw new HttpsError("failed-precondition", "No pending draw offer.");
    }

    if (drawOffer.offeredBy === uid) {
      throw new HttpsError("failed-precondition", "Cannot respond to own offer.");
    }

    assertParticipant(uid, parsed.whiteUid, parsed.blackUid);

    const now = admin.firestore.FieldValue.serverTimestamp();
    transaction.update(gameRef, {
      status: "finished",
      result: "draw",
      endReason: "draw_agreement",
      drawOffer: null,
      updatedAt: now,
    });
    transaction.update(db.collection(COLLECTIONS.users).doc(parsed.whiteUid), {
      activeGameId: null,
      updatedAt: now,
    });
    transaction.update(db.collection(COLLECTIONS.users).doc(parsed.blackUid), {
      activeGameId: null,
      updatedAt: now,
    });

    return { mode: parsed.mode };
  });

  if (finish.mode === "rated") {
    await finalizeRatedGame(data.gameId, "draw");
  }

  return { success: true, accepted: true, result: "draw" };
});

interface ClaimTimeoutRequest extends GameActionRequest {
  timedOutSide: "white" | "black";
}

/**
 * Callable: claim victory when opponent's clock expires.
 */
export const claimTimeout = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  const uid = request.auth.uid;
  const data = request.data as ClaimTimeoutRequest;

  if (!data?.gameId) {
    throw new HttpsError("invalid-argument", "Missing gameId.");
  }

  if (data.timedOutSide !== "white" && data.timedOutSide !== "black") {
    throw new HttpsError("invalid-argument", "Invalid timedOutSide.");
  }

  const gameRef = db.collection(COLLECTIONS.games).doc(data.gameId);
  const gameSnap = await gameRef.get();

  if (!gameSnap.exists) {
    throw new HttpsError("not-found", "Game not found.");
  }

  const game = gameSnap.data()!;
  const parsed = getGameOrThrow(game);

  if (parsed.status !== "active") {
    throw new HttpsError("failed-precondition", "Game is not active.");
  }

  assertParticipant(uid, parsed.whiteUid, parsed.blackUid);

  if (data.timedOutSide === "white" && uid === parsed.whiteUid) {
    throw new HttpsError("failed-precondition", "Cannot claim timeout on yourself.");
  }
  if (data.timedOutSide === "black" && uid === parsed.blackUid) {
    throw new HttpsError("failed-precondition", "Cannot claim timeout on yourself.");
  }

  const result: GameResult =
    data.timedOutSide === "white" ? "black_wins" : "white_wins";

  const finish = await db.runTransaction(async (transaction) => {
    const freshSnap = await transaction.get(gameRef);
    if (!freshSnap.exists) {
      throw new HttpsError("not-found", "Game not found.");
    }

    const freshGame = freshSnap.data()!;
    const freshParsed = getGameOrThrow(freshGame);

    if (freshParsed.status !== "active") {
      throw new HttpsError("failed-precondition", "Game is not active.");
    }

    assertParticipant(uid, freshParsed.whiteUid, freshParsed.blackUid);

    const whiteMillis = (freshGame.whiteMillis as number) ?? 600000;
    const blackMillis = (freshGame.blackMillis as number) ?? 600000;
    const elapsed = elapsedSinceLastMove(freshGame);
    const turn = freshParsed.turn as "white" | "black";

    const claimedRemaining = remainingClockMillis(
      data.timedOutSide,
      turn,
      whiteMillis,
      blackMillis,
      elapsed,
    );

    if (claimedRemaining > 0) {
      throw new HttpsError("failed-precondition", "Clock has not expired.");
    }

    const now = admin.firestore.FieldValue.serverTimestamp();
    transaction.update(gameRef, {
      status: "finished",
      result,
      endReason: "timeout",
      timedOutSide: data.timedOutSide,
      updatedAt: now,
    });
    transaction.update(db.collection(COLLECTIONS.users).doc(freshParsed.whiteUid), {
      activeGameId: null,
      updatedAt: now,
    });
    transaction.update(db.collection(COLLECTIONS.users).doc(freshParsed.blackUid), {
      activeGameId: null,
      updatedAt: now,
    });

    return { mode: freshParsed.mode };
  });

  if (finish.mode === "rated") {
    await finalizeRatedGame(data.gameId, result);
  }

  return { success: true, result };
});
