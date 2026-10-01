import 'package:chess/chess_engine/src/castling_rights.dart';
import 'package:chess/chess_engine/src/piece.dart';
import 'package:chess/chess_engine/src/position.dart';
import 'package:chess/chess_engine/src/square.dart';

/// FEN parsing and serialization.
abstract final class FenParser {
  static const String startingFen =
      'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

  static Position fromFen(String fen) {
    final parts = fen.trim().split(RegExp(r'\s+'));
    if (parts.length != 6) {
      throw FormatException('Invalid FEN: expected 6 fields', fen);
    }

    final board = List<Piece?>.filled(64, null);
    final ranks = parts[0].split('/');
    if (ranks.length != 8) {
      throw FormatException('Invalid FEN board', fen);
    }

    for (var rank = 0; rank < 8; rank++) {
      var file = 0;
      for (final char in ranks[7 - rank].split('')) {
        if (char.isEmpty) continue;
        final digit = int.tryParse(char);
        if (digit != null) {
          file += digit;
        } else {
          final piece = Piece.fromFenChar(char);
          if (piece == null) {
            throw FormatException('Invalid FEN piece: $char', fen);
          }
          board[file + rank * 8] = piece;
          file++;
        }
      }
    }

    final side = parts[1] == 'w' ? ChessColor.white : ChessColor.black;
    final castling = CastlingRights.fromFen(parts[2]);
    final ep = parts[3] == '-' ? null : Square.fromAlgebraic(parts[3]);

    return Position(
      board: board,
      sideToMove: side,
      castlingRights: castling,
      enPassantSquare: ep,
      halfmoveClock: int.parse(parts[4]),
      fullmoveNumber: int.parse(parts[5]),
    );
  }

  static String toFen(Position position) {
    final ranks = <String>[];
    for (var rank = 7; rank >= 0; rank--) {
      final buffer = StringBuffer();
      var empty = 0;
      for (var file = 0; file < 8; file++) {
        final piece = position.board[file + rank * 8];
        if (piece == null) {
          empty++;
        } else {
          if (empty > 0) {
            buffer.write(empty);
            empty = 0;
          }
          buffer.write(piece.fenChar);
        }
      }
      if (empty > 0) buffer.write(empty);
      ranks.add(buffer.toString());
    }

    final ep = position.enPassantSquare?.algebraic ?? '-';
    final side = position.sideToMove == ChessColor.white ? 'w' : 'b';

    return '${ranks.join('/')}'
        ' $side'
        ' ${position.castlingRights.fen}'
        ' $ep'
        ' ${position.halfmoveClock}'
        ' ${position.fullmoveNumber}';
  }
}
