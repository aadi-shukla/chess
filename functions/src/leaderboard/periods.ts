/** Returns ISO week period key e.g. `2026-W13`. */
export function getWeeklyPeriodKey(date: Date = new Date()): string {
  const utc = new Date(
    Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()),
  );
  const day = utc.getUTCDay() || 7;
  utc.setUTCDate(utc.getUTCDate() + 4 - day);
  const yearStart = new Date(Date.UTC(utc.getUTCFullYear(), 0, 1));
  const week = Math.ceil(
    ((utc.getTime() - yearStart.getTime()) / 86_400_000 + 1) / 7,
  );
  return `${utc.getUTCFullYear()}-W${week.toString().padStart(2, "0")}`;
}

/** Returns month period key e.g. `2026-06`. */
export function getMonthlyPeriodKey(date: Date = new Date()): string {
  const month = (date.getUTCMonth() + 1).toString().padStart(2, "0");
  return `${date.getUTCFullYear()}-${month}`;
}

export type LeaderboardScope = "global" | "weekly" | "monthly";

export function getBoardId(
  scope: LeaderboardScope,
  date: Date = new Date(),
): string {
  switch (scope) {
  case "weekly":
    return `weekly-${getWeeklyPeriodKey(date)}`;
  case "monthly":
    return `monthly-${getMonthlyPeriodKey(date)}`;
  default:
    return "global";
  }
}
