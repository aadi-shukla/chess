import { HttpsError } from "firebase-functions/v2/https";

export type GameMode = "casual" | "rated";

export const ALLOWED_TIME_CONTROLS = [
  "3+0",
  "3+2",
  "5+0",
  "5+3",
  "10+0",
  "10+5",
  "15+10",
  "30+0",
] as const;

export type AllowedTimeControl = (typeof ALLOWED_TIME_CONTROLS)[number];

export function parseGameMode(value: unknown): GameMode {
  if (value !== "casual" && value !== "rated") {
    throw new HttpsError("invalid-argument", "Invalid matchmaking mode.");
  }
  return value;
}

export function assertValidTimeControl(value: unknown): AllowedTimeControl {
  const timeControl = typeof value === "string" ? value.trim() : "";
  if (!ALLOWED_TIME_CONTROLS.includes(timeControl as AllowedTimeControl)) {
    throw new HttpsError(
      "invalid-argument",
      `Invalid time control. Allowed: ${ALLOWED_TIME_CONTROLS.join(", ")}`,
    );
  }
  return timeControl as AllowedTimeControl;
}

export function parseTimeControlMillis(timeControl: string): {
  minutes: number;
  incrementSeconds: number;
} {
  const parts = timeControl.split("+");
  const minutes = parseInt(parts[0] ?? "10", 10) || 10;
  const incrementSeconds = parseInt(parts[1] ?? "0", 10) || 0;
  return { minutes, incrementSeconds };
}

/** Remaining clock time for a side given stored millis and elapsed on the active clock. */
export function remainingClockMillis(
  side: "white" | "black",
  turn: "white" | "black",
  whiteMillis: number,
  blackMillis: number,
  elapsed: number,
): number {
  const stored = side === "white" ? whiteMillis : blackMillis;
  if (side === turn) {
    return Math.max(0, stored - elapsed);
  }
  return stored;
}
