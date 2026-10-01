import { expect } from "chai";
import { applyMove, parseTimeControl } from "../src/game/chess_engine";

describe("chess_engine", () => {
  const startFen =
    "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

  it("applies legal opening move", () => {
    const result = applyMove(startFen, "e2", "e4");
    expect(result.san).to.equal("e4");
    expect(result.isGameOver).to.equal(false);
    expect(result.fen).to.contain("4P3");
  });

  it("rejects illegal move", () => {
    expect(() => applyMove(startFen, "e2", "e5")).to.throw();
  });

  it("parses time control", () => {
    expect(parseTimeControl("10+5")).to.deep.equal({
      minutes: 10,
      incrementSeconds: 5,
    });
  });
});
