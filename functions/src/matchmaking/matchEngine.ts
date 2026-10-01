import {
  BAND_EXPAND_INTERVAL_MS,
  BAND_EXPAND_STEP,
  RATING_BAND_MAX,
  RATING_BAND_START,
} from "./constants";
import { MatchType } from "./types";

export interface QueueCandidate {
  id: string;
  userId: string;
  rating: number;
  createdAtMs: number;
}

/**
 * Expands the rating search band based on how long the player has waited.
 */
export function computeRatingBand(waitMs: number): number {
  const steps = Math.floor(waitMs / BAND_EXPAND_INTERVAL_MS);
  return Math.min(RATING_BAND_MAX, RATING_BAND_START + steps * BAND_EXPAND_STEP);
}

/**
 * Picks the closest-rated opponent that is not the requesting user.
 * Random match type ignores rating distance and picks the longest-waiting opponent.
 */
export function pickOpponent(
  candidates: QueueCandidate[],
  uid: string,
  rating: number,
  matchType: MatchType,
): QueueCandidate | null {
  const others = candidates.filter((c) => c.userId !== uid);
  if (others.length === 0) return null;

  if (matchType === "random") {
    return others.reduce((best, current) =>
      current.createdAtMs < best.createdAtMs ? current : best,
    );
  }

  return others.reduce((best, current) => {
    const currentDiff = Math.abs(current.rating - rating);
    const bestDiff = Math.abs(best.rating - rating);
    if (currentDiff !== bestDiff) {
      return currentDiff < bestDiff ? current : best;
    }
    return current.createdAtMs < best.createdAtMs ? current : best;
  });
}

/**
 * Returns true when opponent rating is within the active search band.
 */
export function isWithinRatingBand(
  playerRating: number,
  opponentRating: number,
  band: number,
  matchType: MatchType,
): boolean {
  if (matchType === "random") return true;
  return Math.abs(playerRating - opponentRating) <= band;
}
