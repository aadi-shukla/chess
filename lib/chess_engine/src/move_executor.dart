import 'package:chess/chess_engine/src/castling_rights.dart';
import 'package:chess/chess_engine/src/move.dart';
import 'package:chess/chess_engine/src/piece.dart';
import 'package:chess/chess_engine/src/position.dart';
import 'package:chess/chess_engine/src/square.dart';

/// Applies moves to positions (immutable copy-on-write).
abstract final class MoveExecutor {
  static Position apply(Position position, ChessMove move) {
    final board = List<Piece?>.from(position.board);
    final piece = board[move.from.boardIndex]!;
    final captured = board[move.to.boardIndex];

    board[move.from.boardIndex] = null;

    if (move.isEnPassant) {
      final capturedIndex =
          move.to.boardIndex + (piece.color == ChessColor.white ? -8 : 8);
      board[capturedIndex] = null;
      board[move.to.boardIndex] = piece;
    } else if (move.isCastle) {
      _applyCastle(board, move, piece.color);
      board[move.to.boardIndex] = piece;
    } else {
      final placed = _isPromotion(move, piece)
          ? Piece(color: piece.color, type: move.promotion)
          : piece;
      board[move.to.boardIndex] = placed;
    }

    final castlingRights = _updateCastlingRights(
      position.castlingRights,
      move,
      piece,
    );
    final enPassantSquare = _updateEnPassant(move, piece);
    final halfmoveClock = _updateHalfmoveClock(
      position.halfmoveClock,
      move,
      piece,
      captured,
    );

    final nextSide = position.sideToMove.opposite;
    final fullmove = nextSide == ChessColor.white
        ? position.fullmoveNumber + 1
        : position.fullmoveNumber;

    return Position(
      board: board,
      sideToMove: nextSide,
      castlingRights: castlingRights,
      enPassantSquare: enPassantSquare,
      halfmoveClock: halfmoveClock,
      fullmoveNumber: fullmove,
    );
  }

  static bool _isPromotion(ChessMove move, Piece piece) {
    if (piece.type != PieceType.pawn) return false;
    return (piece.color == ChessColor.white && move.to.rank == 7) ||
        (piece.color == ChessColor.black && move.to.rank == 0);
  }

  static void _applyCastle(
    List<Piece?> board,
    ChessMove move,
    ChessColor color,
  ) {
    final rank = color == ChessColor.white ? 0 : 7;
    if (move.to.file == 6) {
      final rookFrom = 7 + rank * 8;
      final rookTo = 5 + rank * 8;
      board[rookTo] = board[rookFrom];
      board[rookFrom] = null;
    } else if (move.to.file == 2) {
      final rookFrom = 0 + rank * 8;
      final rookTo = 3 + rank * 8;
      board[rookTo] = board[rookFrom];
      board[rookFrom] = null;
    }
  }

  static CastlingRights _updateCastlingRights(
    CastlingRights rights,
    ChessMove move,
    Piece piece,
  ) {
    var updated = rights;

    if (piece.type == PieceType.king) {
      updated = updated.revokeColor(piece.color);
    }

    if (piece.type == PieceType.rook) {
      updated = _revokeRookFrom(updated, move.from);
    }

    if (move.isCapture && !move.isEnPassant) {
      updated = _revokeRookFrom(updated, move.to);
    }

    return updated;
  }

  static CastlingRights _revokeRookFrom(
    CastlingRights rights,
    Square square,
  ) {
    if (square == Square.a1) {
      return rights.without(ChessColor.white, kingSide: false);
    }
    if (square == Square.h1) {
      return rights.without(ChessColor.white, kingSide: true);
    }
    if (square == Square.a8) {
      return rights.without(ChessColor.black, kingSide: false);
    }
    if (square == Square.h8) {
      return rights.without(ChessColor.black, kingSide: true);
    }
    return rights;
  }

  static Square? _updateEnPassant(ChessMove move, Piece piece) {
    if (move.isDoublePawnPush) {
      final epRank = piece.color == ChessColor.white ? 2 : 5;
      return Square.fromIndex(move.from.file + epRank * 8);
    }
    return null;
  }

  static int _updateHalfmoveClock(
    int current,
    ChessMove move,
    Piece piece,
    Piece? captured,
  ) {
    if (piece.type == PieceType.pawn ||
        captured != null ||
        move.isEnPassant ||
        move.isCapture) {
      return 0;
    }
    return current + 1;
  }
}
