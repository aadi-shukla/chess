import * as admin from "firebase-admin";
import { randomInt } from "crypto";
import { HttpsError } from "firebase-functions/v2/https";
import { db, COLLECTIONS } from "../utils/db";
import {
  assertValidTimeControl,
  parseGameMode,
  parseTimeControlMillis,
} from "../utils/gameValidation";
import {
  INVITE_EXPIRY_MS,
  INVITE_CODE_LENGTH,
  OPPONENT_QUERY_LIMIT,
  QUEUE_TIMEOUT_MS,
} from "./constants";
import {
  computeRatingBand,
  isWithinRatingBand,
  pickOpponent,
  QueueCandidate,
} from "./matchEngine";
import { GameMode, JoinQueueRequest, MatchType, QueueEntry } from "./types";

function assertAuth(uid: string | undefined): asserts uid is string {
  if (!uid) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }
}

function parseMatchType(value: unknown): MatchType {
  if (value === "random") return "random";
  return "rated";
}

async function assertNotInActiveGame(uid: string): Promise<number> {
  const userRef = db.collection(COLLECTIONS.users).doc(uid);
  const userSnap = await userRef.get();

  if (!userSnap.exists) {
    throw new HttpsError("failed-precondition", "User profile not found.");
  }

  const userData = userSnap.data()!;
  if (userData.activeGameId) {
    throw new HttpsError("failed-precondition", "Already in an active game.");
  }

  return (userData.rating as number) ?? 1200;
}

async function clearWaitingEntries(uid: string): Promise<void> {
  const existing = await db
    .collection(COLLECTIONS.matchmaking)
    .where("userId", "==", uid)
    .where("status", "==", "waiting")
    .get();

  if (existing.empty) return;

  const batch = db.batch();
  existing.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
}

async function fetchOpponents(
  mode: GameMode,
  timeControl: string,
  matchType: MatchType,
  rating: number,
  band: number,
): Promise<QueueCandidate[]> {
  let query = db
    .collection(COLLECTIONS.matchmaking)
    .where("status", "==", "waiting")
    .where("mode", "==", mode)
    .where("timeControl", "==", timeControl);

  if (matchType === "rated") {
    query = query
      .where("rating", ">=", rating - band)
      .where("rating", "<=", rating + band)
      .orderBy("rating")
      .orderBy("createdAt");
  } else {
    query = query.orderBy("createdAt");
  }

  const snapshot = await query.limit(OPPONENT_QUERY_LIMIT).get();

  return snapshot.docs.map((doc) => {
    const data = doc.data();
    const createdAt = data.createdAt as admin.firestore.Timestamp;
    return {
      id: doc.id,
      userId: data.userId as string,
      rating: (data.rating as number) ?? 1200,
      createdAtMs: createdAt.toMillis(),
    };
  });
}

async function tryMatchQueueEntry(
  queueRef: FirebaseFirestore.DocumentReference,
  queueData: QueueEntry,
): Promise<{ status: "matched"; gameId: string } | { status: "waiting"; queueId: string; ratingBand: number }> {
  const uid = queueData.userId;
  const waitMs = Date.now() - queueData.createdAt.toMillis();
  const band = computeRatingBand(waitMs);

  await queueRef.update({ ratingBand: band });

  const candidates = await fetchOpponents(
    queueData.mode,
    queueData.timeControl,
    queueData.matchType,
    queueData.rating,
    band,
  );

  const opponent = pickOpponent(
    candidates.filter((c) =>
      isWithinRatingBand(queueData.rating, c.rating, band, queueData.matchType),
    ),
    uid,
    queueData.rating,
    queueData.matchType,
  );

  if (!opponent) {
    return { status: "waiting", queueId: queueRef.id, ratingBand: band };
  }

  const opponentRef = db.collection(COLLECTIONS.matchmaking).doc(opponent.id);
  const gameId = await db.runTransaction(async (transaction) => {
    const [freshQueue, freshOpponent] = await Promise.all([
      transaction.get(queueRef),
      transaction.get(opponentRef),
    ]);

    if (!freshQueue.exists || !freshOpponent.exists) {
      throw new HttpsError("aborted", "Queue entry no longer available.");
    }

    const freshQueueData = freshQueue.data() as QueueEntry;
    const freshOpponentData = freshOpponent.data() as QueueEntry;

    if (
      freshQueueData.status !== "waiting" ||
      freshOpponentData.status !== "waiting"
    ) {
      throw new HttpsError("aborted", "Opponent already matched.");
    }

    const createdGameId = db.collection(COLLECTIONS.games).doc().id;
    const startedAt = admin.firestore.Timestamp.now();
    const { minutes, incrementSeconds } = parseTimeControlFromString(
      queueData.timeControl,
    );
    const startingMillis = minutes * 60 * 1000;
    const serverNow = admin.firestore.FieldValue.serverTimestamp();

    const whiteUid = uid;
    const blackUid = opponent.userId;
    const whiteRef = db.collection(COLLECTIONS.users).doc(whiteUid);
    const blackRef = db.collection(COLLECTIONS.users).doc(blackUid);
    const [whiteSnap, blackSnap] = await Promise.all([
      transaction.get(whiteRef),
      transaction.get(blackRef),
    ]);

    if (whiteSnap.data()?.activeGameId || blackSnap.data()?.activeGameId) {
      throw new HttpsError("aborted", "Opponent already in a game.");
    }

    transaction.set(db.collection(COLLECTIONS.games).doc(createdGameId), {
      whiteUid,
      blackUid,
      status: "active",
      fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
      turn: "white",
      moveHistory: [],
      version: 1,
      timeControl: queueData.timeControl,
      mode: queueData.mode,
      whiteMillis: startingMillis,
      blackMillis: startingMillis,
      incrementMillis: incrementSeconds * 1000,
      lastMoveAt: startedAt,
      drawOffer: null,
      createdAt: startedAt,
      updatedAt: startedAt,
    });

    transaction.update(queueRef, {
      status: "matched",
      matchedGameId: createdGameId,
      updatedAt: serverNow,
    });
    transaction.update(opponentRef, {
      status: "matched",
      matchedGameId: createdGameId,
      updatedAt: serverNow,
    });
    transaction.update(whiteRef, { activeGameId: createdGameId, updatedAt: serverNow });
    transaction.update(blackRef, { activeGameId: createdGameId, updatedAt: serverNow });

    return createdGameId;
  });

  await db.runTransaction(async (transaction) => {
    transaction.delete(queueRef);
    transaction.delete(opponentRef);
  });

  return { status: "matched", gameId };
}

function parseTimeControlFromString(timeControl: string): {
  minutes: number;
  incrementSeconds: number;
} {
  return parseTimeControlMillis(timeControl);
}

export async function joinQueueHandler(
  uid: string,
  data: JoinQueueRequest,
): Promise<Record<string, unknown>> {
  const mode = parseGameMode(data.mode);
  const matchType = parseMatchType(data.matchType);
  const timeControl = assertValidTimeControl(data.timeControl ?? "10+0");
  const rating = await assertNotInActiveGame(uid);

  await clearWaitingEntries(uid);

  const now = admin.firestore.Timestamp.now();
  const expiresAt = admin.firestore.Timestamp.fromMillis(
    Date.now() + QUEUE_TIMEOUT_MS,
  );

  const queueRef = db.collection(COLLECTIONS.matchmaking).doc();
  const queueData: QueueEntry = {
    userId: uid,
    rating,
    mode,
    matchType,
    timeControl,
    status: "waiting",
    ratingBand: computeRatingBand(0),
    createdAt: now,
    expiresAt,
  };

  await queueRef.set(queueData);

  try {
    const result = await tryMatchQueueEntry(queueRef, queueData);
    return result;
  } catch (error) {
    if (error instanceof HttpsError && error.code === "aborted") {
      const retry = await tryMatchQueueEntry(queueRef, queueData);
      return retry;
    }
    throw error;
  }
}

export async function pollQueueHandler(
  uid: string,
  queueId: string,
): Promise<Record<string, unknown>> {
  const queueRef = db.collection(COLLECTIONS.matchmaking).doc(queueId);
  const queueSnap = await queueRef.get();

  if (!queueSnap.exists) {
    const userSnap = await db.collection(COLLECTIONS.users).doc(uid).get();
    const activeGameId = userSnap.data()?.activeGameId as string | undefined;
    if (activeGameId) {
      return { status: "matched", gameId: activeGameId };
    }
    throw new HttpsError("not-found", "Queue entry not found or expired.");
  }

  const queueData = queueSnap.data() as QueueEntry;
  if (queueData.userId !== uid) {
    throw new HttpsError("permission-denied", "Not your queue entry.");
  }

  if (queueData.status === "matched" && queueData.matchedGameId) {
    return { status: "matched", gameId: queueData.matchedGameId };
  }

  if (queueData.expiresAt.toMillis() < Date.now()) {
    await queueRef.delete();
    throw new HttpsError("deadline-exceeded", "Queue entry expired.");
  }

  return tryMatchQueueEntry(queueRef, queueData);
}

export async function getQueueStatusHandler(
  uid: string,
): Promise<Record<string, unknown>> {
  const snapshot = await db
    .collection(COLLECTIONS.matchmaking)
    .where("userId", "==", uid)
    .where("status", "==", "waiting")
    .limit(1)
    .get();

  if (snapshot.empty) {
    const userSnap = await db.collection(COLLECTIONS.users).doc(uid).get();
    const activeGameId = userSnap.data()?.activeGameId as string | undefined;
    if (activeGameId) {
      return { status: "matched", gameId: activeGameId };
    }
    return { status: "idle" };
  }

  const doc = snapshot.docs[0]!;
  const data = doc.data() as QueueEntry;
  const waitMs = Date.now() - data.createdAt.toMillis();

  return {
    status: "waiting",
    queueId: doc.id,
    mode: data.mode,
    matchType: data.matchType,
    timeControl: data.timeControl,
    ratingBand: computeRatingBand(waitMs),
    waitSeconds: Math.floor(waitMs / 1000),
    expiresAt: data.expiresAt.toMillis(),
  };
}

export async function leaveQueueHandler(uid: string): Promise<{ removed: number }> {
  const entries = await db
    .collection(COLLECTIONS.matchmaking)
    .where("userId", "==", uid)
    .where("status", "==", "waiting")
    .get();

  const batch = db.batch();
  entries.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();

  return { removed: entries.size };
}

function generateInviteCode(): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let code = "";
  for (let i = 0; i < INVITE_CODE_LENGTH; i++) {
    code += chars[randomInt(chars.length)];
  }
  return code;
}

export async function createMatchHandler(
  uid: string,
  mode: GameMode,
  timeControl: string,
): Promise<Record<string, unknown>> {
  await assertNotInActiveGame(uid);

  const existingInvites = await db
    .collection(COLLECTIONS.matchInvites)
    .where("hostUid", "==", uid)
    .where("status", "==", "open")
    .get();

  const batch = db.batch();
  existingInvites.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();

  let inviteCode = generateInviteCode();
  for (let attempt = 0; attempt < 5; attempt++) {
    const existing = await db
      .collection(COLLECTIONS.matchInvites)
      .doc(inviteCode)
      .get();
    if (!existing.exists) break;
    inviteCode = generateInviteCode();
  }

  const now = admin.firestore.Timestamp.now();
  const expiresAt = admin.firestore.Timestamp.fromMillis(
    Date.now() + INVITE_EXPIRY_MS,
  );

  await db.collection(COLLECTIONS.matchInvites).doc(inviteCode).set({
    code: inviteCode,
    hostUid: uid,
    mode,
    timeControl,
    status: "open",
    createdAt: now,
    expiresAt,
  });

  return {
    inviteCode,
    expiresAt: expiresAt.toMillis(),
    mode,
    timeControl,
  };
}

export async function joinMatchHandler(
  uid: string,
  inviteCode: string,
): Promise<Record<string, unknown>> {
  const normalizedCode = inviteCode.trim().toUpperCase();
  if (normalizedCode.length < 4) {
    throw new HttpsError("invalid-argument", "Invalid invite code.");
  }

  await assertNotInActiveGame(uid);

  const inviteRef = db.collection(COLLECTIONS.matchInvites).doc(normalizedCode);

  const gameId = await db.runTransaction(async (transaction) => {
    const inviteSnap = await transaction.get(inviteRef);
    if (!inviteSnap.exists) {
      throw new HttpsError("not-found", "Invite not found.");
    }

    const invite = inviteSnap.data()!;
    if (invite.status !== "open") {
      throw new HttpsError("failed-precondition", "Invite is no longer available.");
    }

    if (invite.expiresAt.toMillis() < Date.now()) {
      throw new HttpsError("deadline-exceeded", "Invite has expired.");
    }

    const hostUid = invite.hostUid as string;
    if (hostUid === uid) {
      throw new HttpsError("failed-precondition", "Cannot join your own invite.");
    }

    const hostRef = db.collection(COLLECTIONS.users).doc(hostUid);
    const guestRef = db.collection(COLLECTIONS.users).doc(uid);
    const [hostSnap, guestSnap] = await Promise.all([
      transaction.get(hostRef),
      transaction.get(guestRef),
    ]);

    if (!hostSnap.exists || !guestSnap.exists) {
      throw new HttpsError("failed-precondition", "Player profile not found.");
    }

    if (hostSnap.data()?.activeGameId || guestSnap.data()?.activeGameId) {
      throw new HttpsError("failed-precondition", "Player already in a game.");
    }

    const createdGameId = db.collection(COLLECTIONS.games).doc().id;
    const startedAt = admin.firestore.Timestamp.now();
    const timeControl = invite.timeControl as string;
    const mode = invite.mode as GameMode;
    const { minutes, incrementSeconds } = parseTimeControlFromString(timeControl);
    const startingMillis = minutes * 60 * 1000;
    const serverNow = admin.firestore.FieldValue.serverTimestamp();

    transaction.set(db.collection(COLLECTIONS.games).doc(createdGameId), {
      whiteUid: hostUid,
      blackUid: uid,
      status: "active",
      fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
      turn: "white",
      moveHistory: [],
      version: 1,
      timeControl,
      mode,
      whiteMillis: startingMillis,
      blackMillis: startingMillis,
      incrementMillis: incrementSeconds * 1000,
      lastMoveAt: startedAt,
      drawOffer: null,
      createdAt: startedAt,
      updatedAt: startedAt,
    });

    transaction.update(inviteRef, {
      status: "started",
      guestUid: uid,
      gameId: createdGameId,
      updatedAt: serverNow,
    });
    transaction.update(hostRef, { activeGameId: createdGameId, updatedAt: serverNow });
    transaction.update(guestRef, { activeGameId: createdGameId, updatedAt: serverNow });

    return createdGameId;
  });

  return { status: "matched", gameId };
}

export async function cleanupQueueHandler(): Promise<{ removed: number }> {
  const now = admin.firestore.Timestamp.now();
  const stale = await db
    .collection(COLLECTIONS.matchmaking)
    .where("expiresAt", "<", now)
    .limit(200)
    .get();

  const batch = db.batch();
  stale.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();

  const expiredInvites = await db
    .collection(COLLECTIONS.matchInvites)
    .where("expiresAt", "<", now)
    .where("status", "==", "open")
    .limit(200)
    .get();

  const inviteBatch = db.batch();
  expiredInvites.docs.forEach((doc) => inviteBatch.delete(doc.ref));
  await inviteBatch.commit();

  return { removed: stale.size + expiredInvites.size };
}

export { assertAuth };
