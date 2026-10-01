import { expect } from "chai";
import {
  computeRatingBand,
  isWithinRatingBand,
  pickOpponent,
} from "../src/matchmaking/matchEngine";

describe("matchEngine", () => {
  const candidates = [
    { id: "a", userId: "u1", rating: 1200, createdAtMs: 1000 },
    { id: "b", userId: "u2", rating: 1350, createdAtMs: 2000 },
    { id: "c", userId: "u3", rating: 1210, createdAtMs: 500 },
  ];

  it("expands rating band over wait time", () => {
    expect(computeRatingBand(0)).to.equal(150);
    expect(computeRatingBand(15_000)).to.equal(200);
    expect(computeRatingBand(120_000)).to.equal(500);
  });

  it("picks closest rated opponent", () => {
    const pick = pickOpponent(candidates, "self", 1200, "rated");
    expect(pick?.userId).to.equal("u1");
  });

  it("picks longest-waiting opponent for random match", () => {
    const pick = pickOpponent(candidates, "self", 1200, "random");
    expect(pick?.userId).to.equal("u3");
  });

  it("respects rating band for rated matches", () => {
    expect(isWithinRatingBand(1200, 1350, 100, "rated")).to.equal(false);
    expect(isWithinRatingBand(1200, 1350, 150, "rated")).to.equal(true);
    expect(isWithinRatingBand(1200, 2000, 500, "random")).to.equal(true);
  });

  it("excludes self from opponent pool", () => {
    const pick = pickOpponent(candidates, "u2", 1200, "rated");
    expect(pick?.userId).not.to.equal("u2");
  });
});
