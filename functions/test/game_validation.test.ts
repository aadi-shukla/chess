import { expect } from "chai";
import {
  ALLOWED_TIME_CONTROLS,
  assertValidTimeControl,
  parseGameMode,
  remainingClockMillis,
} from "../src/utils/gameValidation";

describe("gameValidation", () => {
  it("accepts allowed time controls", () => {
    for (const tc of ALLOWED_TIME_CONTROLS) {
      expect(assertValidTimeControl(tc)).to.equal(tc);
    }
  });

  it("rejects arbitrary time controls", () => {
    expect(() => assertValidTimeControl("999+999")).to.throw();
  });

  it("parses game modes", () => {
    expect(parseGameMode("casual")).to.equal("casual");
    expect(parseGameMode("rated")).to.equal("rated");
    expect(() => parseGameMode("hacked")).to.throw();
  });

  it("computes remaining clock for inactive side", () => {
    const remaining = remainingClockMillis(
      "white",
      "black",
      120_000,
      90_000,
      5_000,
    );
    expect(remaining).to.equal(120_000);
  });

  it("computes remaining clock for active side", () => {
    const remaining = remainingClockMillis(
      "black",
      "black",
      120_000,
      90_000,
      5_000,
    );
    expect(remaining).to.equal(85_000);
  });

  it("keeps white clock full when black is on the clock", () => {
    const whiteRemaining = remainingClockMillis(
      "white",
      "black",
      120_000,
      90_000,
      1_000,
    );
    expect(whiteRemaining).to.equal(120_000);
  });
});
