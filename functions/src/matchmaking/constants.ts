/** Initial rating search band (±). */
export const RATING_BAND_START = 150;

/** Maximum rating search band (±). */
export const RATING_BAND_MAX = 500;

/** Milliseconds between each band expansion step. */
export const BAND_EXPAND_INTERVAL_MS = 15_000;

/** Rating points added per expansion step. */
export const BAND_EXPAND_STEP = 50;

/** Queue entry TTL — stale entries are removed. */
export const QUEUE_TIMEOUT_MS = 120_000;

/** Private invite TTL. */
export const INVITE_EXPIRY_MS = 15 * 60 * 1000;

/** Invite code length. */
export const INVITE_CODE_LENGTH = 6;

/** Max opponents fetched per match attempt. */
export const OPPONENT_QUERY_LIMIT = 10;
