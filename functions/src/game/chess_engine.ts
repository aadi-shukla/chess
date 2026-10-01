import { Chess } from "chess.js";

export const STARTING_FEN =
  "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

export interface ValidatedMove {
  san: string;
  fen: string;
  isGameOver: boolean;
  result: "white_wins" | "black_wins" | "draw" | null;
  endReason: string | null;
}

/**
 * Applies a move to the current FEN and returns the updated state.
 */
export function applyMove(
  fen: string,
  from: string,
  to: string,
  promotion?: string,
): ValidatedMove {
  const chess = new Chess(fen);

  const move = chess.move({
    from,
    to,
    promotion: promotion as "q" | "r" | "b" | "n" | undefined,
  });

  if (!move) {
    throw new Error("Illegal move.");
  }

  let result: ValidatedMove["result"] = null;
  let endReason: string | null = null;

  if (chess.isGameOver()) {
    if (chess.isCheckmate()) {
      result = chess.turn() === "w" ? "black_wins" : "white_wins";
      endReason = "checkmate";
    } else if (chess.isStalemate()) {
      result = "draw";
      endReason = "stalemate";
    } else if (chess.isDraw()) {
      result = "draw";
      endReason = "draw";
    }
  }

  return {
    san: move.san,
    fen: chess.fen(),
    isGameOver: chess.isGameOver(),
    result,
    endReason,
  };
}

export function parseTimeControl(timeControl: string): {
  minutes: number;
  incrementSeconds: number;
} {
  const parts = timeControl.split("+");
  const minutes = parseInt(parts[0] ?? "10", 10) || 10;
  const incrementSeconds = parseInt(parts[1] ?? "0", 10) || 0;
  return { minutes, incrementSeconds };
}
