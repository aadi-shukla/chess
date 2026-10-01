import 'package:chess/chess_engine/src/attack_detector.dart';
import 'package:chess/chess_engine/src/move.dart';
import 'package:chess/chess_engine/src/move_executor.dart';
import 'package:chess/chess_engine/src/move_generator.dart';
import 'package:chess/chess_engine/src/piece.dart';
import 'package:chess/chess_engine/src/position.dart';
import 'package:chess/chess_engine/src/square.dart';

/// Standard Algebraic Notation conversion.
abstract final class SanConverter {
  static String toSan(Position position, ChessMove move) {
    if (move.isCastle) {
      return move.to.file == 6 ? 'O-O' : 'O-O-O';
    }

    final piece = position.pieceAt(move.from)!;
    final capture = move.isCapture || move.isEnPassant;
    final buffer = StringBuffer();

    if (piece.type != PieceType.pawn) {
      buffer.write(piece.type.fenChar.toUpperCase());
      buffer.write(_disambiguation(position, move, piece));
    } else if (capture) {
      buffer.write(move.from.fileChar);
    }

    if (capture) buffer.write('x');
    buffer.write(move.to.algebraic);

    if (_isPromotion(move, piece)) {
      buffer.write('=');
      buffer.write(move.promotion.fenChar.toUpperCase());
    }

    final next = MoveExecutor.apply(position, move);
    final inCheck = AttackDetector.isInCheck(next, next.sideToMove);
    final isMate = inCheck && MoveGenerator.generateLegalMoves(next).isEmpty;

    if (isMate) {
      buffer.write('#');
    } else if (inCheck) {
      buffer.write('+');
    }

    return buffer.toString();
  }

  static String _disambiguation(
    Position position,
    ChessMove move,
    Piece piece,
  ) {
    final ambiguous = MoveGenerator.generateLegalMoves(position).where((m) {
      if (m.from == move.from) return false;
      final other = position.pieceAt(m.from);
      return other?.type == piece.type && m.to == move.to;
    }).toList();

    if (ambiguous.isEmpty) return '';

    final sameFile = ambiguous.any((m) => m.from.file == move.from.file);
    final sameRank = ambiguous.any((m) => m.from.rank == move.from.rank);

    if (!sameFile && !sameRank) return move.from.algebraic;
    if (!sameFile) return move.from.fileChar;
    if (!sameRank) return '${move.from.rank + 1}';
    return move.from.algebraic;
  }

  static bool _isPromotion(ChessMove move, Piece piece) {
    if (piece.type != PieceType.pawn) return false;
    return (piece.color == ChessColor.white && move.to.rank == 7) ||
        (piece.color == ChessColor.black && move.to.rank == 0);
  }
}

extension on Square {
  String get fileChar => String.fromCharCode('a'.codeUnitAt(0) + file);
}
