import 'package:chess/chess_engine/src/attack_detector.dart';
import 'package:chess/chess_engine/src/move_generator.dart';
import 'package:chess/chess_engine/src/piece.dart';
import 'package:chess/chess_engine/src/position.dart';

/// Terminal and in-progress game outcomes.
enum GameOutcome {
  ongoing,
  check,
  checkmate,
  stalemate,
  drawFiftyMove,
  drawRepetition,
  drawInsufficientMaterial,
}

/// Game status analysis for a position.
class GameStatus {
  const GameStatus({
    required this.outcome,
    required this.legalMoveCount,
    required this.isInCheck,
  });

  final GameOutcome outcome;
  final int legalMoveCount;
  final bool isInCheck;

  bool get isGameOver => outcome != GameOutcome.ongoing && outcome != GameOutcome.check;

  bool get isDraw =>
      outcome == GameOutcome.drawFiftyMove ||
      outcome == GameOutcome.drawRepetition ||
      outcome == GameOutcome.drawInsufficientMaterial;

  static GameStatus analyze(
    Position position, {
    required Map<String, int> repetitionCounts,
  }) {
    final legalMoves = MoveGenerator.generateLegalMoves(position);
    final inCheck = AttackDetector.isInCheck(position, position.sideToMove);

    if (legalMoves.isEmpty) {
      return GameStatus(
        outcome: inCheck ? GameOutcome.checkmate : GameOutcome.stalemate,
        legalMoveCount: 0,
        isInCheck: inCheck,
      );
    }

    if (position.halfmoveClock >= 100) {
      return GameStatus(
        outcome: GameOutcome.drawFiftyMove,
        legalMoveCount: legalMoves.length,
        isInCheck: inCheck,
      );
    }

    final repKey = position.repetitionKey;
    if ((repetitionCounts[repKey] ?? 0) >= 3) {
      return GameStatus(
        outcome: GameOutcome.drawRepetition,
        legalMoveCount: legalMoves.length,
        isInCheck: inCheck,
      );
    }

    if (_isInsufficientMaterial(position)) {
      return GameStatus(
        outcome: GameOutcome.drawInsufficientMaterial,
        legalMoveCount: legalMoves.length,
        isInCheck: inCheck,
      );
    }

    return GameStatus(
      outcome: inCheck ? GameOutcome.check : GameOutcome.ongoing,
      legalMoveCount: legalMoves.length,
      isInCheck: inCheck,
    );
  }

  static bool _isInsufficientMaterial(Position position) {
    final pieces = <PieceType>[];
    for (final piece in position.board) {
      if (piece != null && piece.type != PieceType.king) {
        pieces.add(piece.type);
      }
    }

    if (pieces.isEmpty) return true;
    if (pieces.length == 1 && pieces.first == PieceType.bishop) return true;
    if (pieces.length == 1 && pieces.first == PieceType.knight) return true;
    if (pieces.length == 2 &&
        pieces.every((p) => p == PieceType.bishop || p == PieceType.knight)) {
      return true;
    }

    return false;
  }
}
