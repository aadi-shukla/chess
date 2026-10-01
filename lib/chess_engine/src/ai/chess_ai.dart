import 'package:chess/chess_engine/src/attack_detector.dart';
import 'package:chess/chess_engine/src/move.dart';
import 'package:chess/chess_engine/src/move_executor.dart';
import 'package:chess/chess_engine/src/move_generator.dart';
import 'package:chess/chess_engine/src/piece.dart';
import 'package:chess/chess_engine/src/position.dart';

/// AI difficulty presets mapped to search depth and randomness.
enum AiDifficulty {
  beginner(searchDepth: 1, randomChance: 0.35),
  easy(searchDepth: 2, randomChance: 0),
  medium(searchDepth: 3, randomChance: 0),
  hard(searchDepth: 4, randomChance: 0),
  expert(searchDepth: 5, randomChance: 0);

  const AiDifficulty({
    required this.searchDepth,
    required this.randomChance,
  });

  final int searchDepth;
  final double randomChance;

  String get label => switch (this) {
        AiDifficulty.beginner => 'Beginner',
        AiDifficulty.easy => 'Easy',
        AiDifficulty.medium => 'Medium',
        AiDifficulty.hard => 'Hard',
        AiDifficulty.expert => 'Expert',
      };
}

/// Minimax chess AI with alpha-beta pruning.
abstract final class ChessAi {
  static const Map<PieceType, int> _material = {
    PieceType.pawn: 100,
    PieceType.knight: 320,
    PieceType.bishop: 330,
    PieceType.rook: 500,
    PieceType.queen: 900,
    PieceType.king: 20000,
  };

  /// Picks the best move for [side] at the given [difficulty].
  static ChessMove? findBestMove(
    Position position,
    ChessColor side, {
    AiDifficulty difficulty = AiDifficulty.medium,
  }) {
    final moves = MoveGenerator.generateLegalMoves(position)
        .where((m) => position.pieceAt(m.from)?.color == side)
        .toList();
    if (moves.isEmpty) return null;

    if (difficulty.randomChance > 0) {
      final roll = DateTime.now().microsecondsSinceEpoch % 100 / 100.0;
      if (roll < difficulty.randomChance) {
        return moves[DateTime.now().microsecondsSinceEpoch % moves.length];
      }
    }

    ChessMove? bestMove;
    var bestScore = -999999999;
    final maximizing = position.sideToMove == side;

    for (final move in moves) {
      final next = MoveExecutor.apply(position, move);
      final score = -_search(
        next,
        side,
        difficulty.searchDepth - 1,
        -999999999,
        999999999,
        !maximizing,
      );

      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }

    return bestMove;
  }

  static int _search(
    Position position,
    ChessColor side,
    int depth,
    int alpha,
    int beta,
    bool maximizing,
  ) {
    final status = MoveGenerator.generateLegalMoves(position);
    if (depth == 0 || status.isEmpty) {
      return _evaluate(position, side);
    }

    if (maximizing) {
      var maxEval = -999999999;
      for (final move in status) {
        final next = MoveExecutor.apply(position, move);
        final eval = _search(next, side, depth - 1, alpha, beta, false);
        maxEval = eval > maxEval ? eval : maxEval;
        alpha = alpha > eval ? alpha : eval;
        if (beta <= alpha) break;
      }
      return maxEval;
    }

    var minEval = 999999999;
    for (final move in status) {
      final next = MoveExecutor.apply(position, move);
      final eval = _search(next, side, depth - 1, alpha, beta, true);
      minEval = eval < minEval ? eval : minEval;
      beta = beta < eval ? beta : eval;
      if (beta <= alpha) break;
    }
    return minEval;
  }

  static int _evaluate(Position position, ChessColor side) {
    var score = 0;

    for (final piece in position.board) {
      if (piece == null) continue;
      final value = _material[piece.type] ?? 0;
      score += piece.color == side ? value : -value;
    }

    if (AttackDetector.isInCheck(position, side.opposite)) {
      score += 30;
    }
    if (AttackDetector.isInCheck(position, side)) {
      score -= 30;
    }

    final mobility = MoveGenerator.generateLegalMoves(position).length;
    score += position.sideToMove == side ? mobility * 2 : -mobility * 2;

    return score;
  }
}
