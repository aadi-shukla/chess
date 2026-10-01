import 'package:chess/chess_engine/src/castling_rights.dart';
import 'package:chess/chess_engine/src/piece.dart';
import 'package:chess/chess_engine/src/square.dart';

/// Immutable chess position including board and game state metadata.
class Position {
  Position({
    List<Piece?>? board,
    this.sideToMove = ChessColor.white,
    CastlingRights? castlingRights,
    this.enPassantSquare,
    this.halfmoveClock = 0,
    this.fullmoveNumber = 1,
  })  : board = List<Piece?>.from(board ?? List<Piece?>.filled(64, null)),
        castlingRights = castlingRights ?? const CastlingRights();

  final List<Piece?> board;
  final ChessColor sideToMove;
  final CastlingRights castlingRights;
  final Square? enPassantSquare;
  final int halfmoveClock;
  final int fullmoveNumber;

  Piece? pieceAt(Square square) => board[square.boardIndex];

  void setPiece(Square square, Piece? piece) {
    board[square.boardIndex] = piece;
  }

  Square? findKing(ChessColor color) {
    for (var i = 0; i < 64; i++) {
      final piece = board[i];
      if (piece?.type == PieceType.king && piece?.color == color) {
        return Square.fromIndex(i);
      }
    }
    return null;
  }

  Position copy() {
    return Position(
      board: List<Piece?>.from(board),
      sideToMove: sideToMove,
      castlingRights: castlingRights,
      enPassantSquare: enPassantSquare,
      halfmoveClock: halfmoveClock,
      fullmoveNumber: fullmoveNumber,
    );
  }

  /// Key for threefold repetition (excludes halfmove/fullmove clocks).
  String get repetitionKey {
    final buffer = StringBuffer();
    for (final piece in board) {
      buffer.write(piece?.fenChar ?? '.');
    }
    buffer.write(sideToMove.name);
    buffer.write(castlingRights.fen);
    buffer.write(enPassantSquare?.algebraic ?? '-');
    return buffer.toString();
  }
}
