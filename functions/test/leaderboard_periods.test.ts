import { expect } from "chai";
import {
  getBoardId,
  getMonthlyPeriodKey,
  getWeeklyPeriodKey,
} from "../src/leaderboard/periods";

describe("leaderboard periods", () => {
  it("formats weekly period key", () => {
    const key = getWeeklyPeriodKey(new Date("2026-06-26T12:00:00Z"));
    expect(key).to.match(/^\d{4}-W\d{2}$/);
  });

  it("formats monthly period key", () => {
    expect(getMonthlyPeriodKey(new Date("2026-06-26T12:00:00Z"))).to.equal(
      "2026-06",
    );
  });

  it("resolves board ids by scope", () => {
    const date = new Date("2026-06-26T12:00:00Z");
    expect(getBoardId("global", date)).to.equal("global");
    expect(getBoardId("weekly", date)).to.equal(
      `weekly-${getWeeklyPeriodKey(date)}`,
    );
    expect(getBoardId("monthly", date)).to.equal(
      `monthly-${getMonthlyPeriodKey(date)}`,
    );
  });
});
