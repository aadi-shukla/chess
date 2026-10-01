import { onAuthUserCreate } from "./auth/onUserCreate";
import {
  claimTimeout,
  offerDraw,
  resignGame,
  respondToDraw,
  submitMove,
} from "./game/validateMove";
import { getLeaderboard } from "./leaderboard/getLeaderboard";
import {
  createPrivateMatch,
  getQueueStatus,
  joinMatchmakingQueue,
  joinPrivateMatch,
  leaveMatchmakingQueue,
  pollMatchmakingQueue,
  scheduledMatchmakingCleanup,
} from "./matchmaking";

export {
  onAuthUserCreate,
  joinMatchmakingQueue,
  pollMatchmakingQueue,
  getQueueStatus,
  leaveMatchmakingQueue,
  createPrivateMatch,
  joinPrivateMatch,
  scheduledMatchmakingCleanup,
  getLeaderboard,
  submitMove,
  resignGame,
  offerDraw,
  respondToDraw,
  claimTimeout,
};
