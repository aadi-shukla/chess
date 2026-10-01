import 'package:chess/chess_engine/src/piece.dart';
import 'package:chess/chess_engine/src/position.dart';
import 'package:chess/chess_engine/src/square.dart';

/// Attack detection and check validation utilities.
abstract final class AttackDetector {
  static const List<List<int>> _knightOffsets = [
    [-2, -1],
    [-2, 1],
    [-1, -2],
    [-1, 2],
    [1, -2],
    [1, 2],
    [2, -1],
    [2, 1],
  ];

  static const List<List<int>> _kingOffsets = [
    [-1, -1],
    [-1, 0],
    [-1, 1],
    [0, -1],
    [0, 1],
    [1, -1],
    [1, 0],
    [1, 1],
  ];

  static bool isSquareAttacked(
    Position position,
    Square square,
    ChessColor byColor,
  ) {
    final pawnDir = byColor == ChessColor.white ? 1 : -1;
    for (final fileDelta in [-1, 1]) {
      final attacker = square.offset(fileDelta, -pawnDir);
      if (attacker != null) {
        final piece = position.pieceAt(attacker);
        if (piece?.color == byColor && piece?.type == PieceType.pawn) {
          return true;
        }
      }
    }

    for (final offset in _knightOffsets) {
      final target = square.offset(offset[0], offset[1]);
      if (target != null) {
        final piece = position.pieceAt(target);
        if (piece?.color == byColor && piece?.type == PieceType.knight) {
          return true;
        }
      }
    }

    for (final offset in _kingOffsets) {
      final target = square.offset(offset[0], offset[1]);
      if (target != null) {
        final piece = position.pieceAt(target);
        if (piece?.color == byColor && piece?.type == PieceType.king) {
          return true;
        }
      }
    }

    const directions = [
      [-1, -1],
      [-1, 0],
      [-1, 1],
      [0, -1],
      [0, 1],
      [1, -1],
      [1, 0],
      [1, 1],
    ];

    for (final dir in directions) {
      var current = square;
      while (true) {
        final next = current.offset(dir[0], dir[1]);
        if (next == null) break;
        current = next;
        final piece = position.pieceAt(current);
        if (piece == null) continue;
        if (piece.color != byColor) break;

        final isDiagonal = dir[0] != 0 && dir[1] != 0;
        final isOrthogonal = dir[0] == 0 || dir[1] == 0;
        final canCapture = (piece.type == PieceType.queen) ||
            (piece.type == PieceType.bishop && isDiagonal) ||
            (piece.type == PieceType.rook && isOrthogonal);
        if (canCapture) return true;
        break;
      }
    }

    return false;
  }

  static bool isInCheck(Position position, ChessColor color) {
    final kingSquare = position.findKing(color);
    if (kingSquare == null) return false;
    return isSquareAttacked(position, kingSquare, color.opposite);
  }
}
