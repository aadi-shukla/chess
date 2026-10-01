export type GameMode = "casual" | "rated";
export type MatchType = "rated" | "random";
export type QueueStatus = "waiting" | "matched" | "cancelled";

export interface JoinQueueRequest {
  mode: GameMode;
  timeControl: string;
  matchType?: MatchType;
}

export interface QueueEntry {
  userId: string;
  rating: number;
  mode: GameMode;
  matchType: MatchType;
  timeControl: string;
  status: QueueStatus;
  ratingBand: number;
  createdAt: FirebaseFirestore.Timestamp;
  expiresAt: FirebaseFirestore.Timestamp;
  matchedGameId?: string;
}

export interface CreateMatchRequest {
  mode: GameMode;
  timeControl: string;
}

export interface JoinMatchRequest {
  inviteCode: string;
}
