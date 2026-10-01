import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import {
  assertAuth,
  cleanupQueueHandler,
  createMatchHandler,
  getQueueStatusHandler,
  joinMatchHandler,
  joinQueueHandler,
  leaveQueueHandler,
  pollQueueHandler,
} from "./handlers";
import { CreateMatchRequest, JoinMatchRequest, JoinQueueRequest } from "./types";
import {
  assertValidTimeControl,
  parseGameMode,
} from "../utils/gameValidation";

export const joinMatchmakingQueue = onCall(async (request) => {
  assertAuth(request.auth?.uid);
  return joinQueueHandler(request.auth!.uid, request.data as JoinQueueRequest);
});

export const pollMatchmakingQueue = onCall(async (request) => {
  assertAuth(request.auth?.uid);
  const data = request.data as { queueId?: string };
  if (!data?.queueId) {
    throw new HttpsError("invalid-argument", "queueId is required.");
  }
  return pollQueueHandler(request.auth!.uid, data.queueId);
});

export const getQueueStatus = onCall(async (request) => {
  assertAuth(request.auth?.uid);
  return getQueueStatusHandler(request.auth!.uid);
});

export const leaveMatchmakingQueue = onCall(async (request) => {
  assertAuth(request.auth?.uid);
  return leaveQueueHandler(request.auth!.uid);
});

export const createPrivateMatch = onCall(async (request) => {
  assertAuth(request.auth?.uid);
  const data = request.data as CreateMatchRequest;
  if (!data?.mode || !data?.timeControl) {
    throw new HttpsError("invalid-argument", "mode and timeControl are required.");
  }
  return createMatchHandler(
    request.auth!.uid,
    parseGameMode(data.mode),
    assertValidTimeControl(data.timeControl),
  );
});

export const joinPrivateMatch = onCall(async (request) => {
  assertAuth(request.auth?.uid);
  const data = request.data as JoinMatchRequest;
  if (!data?.inviteCode) {
    throw new HttpsError("invalid-argument", "inviteCode is required.");
  }
  return joinMatchHandler(request.auth!.uid, data.inviteCode);
});

export const scheduledMatchmakingCleanup = onSchedule(
  "every 2 minutes",
  async () => {
    await cleanupQueueHandler();
  },
);
