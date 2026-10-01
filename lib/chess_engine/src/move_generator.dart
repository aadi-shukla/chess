import 'package:chess/chess_engine/src/attack_detector.dart';
import 'package:chess/chess_engine/src/move.dart';
import 'package:chess/chess_engine/src/move_executor.dart';
import 'package:chess/chess_engine/src/piece.dart';
import 'package:chess/chess_engine/src/position.dart';
import 'package:chess/chess_engine/src/square.dart';

/// Generates pseudo-legal and legal chess moves.
abstract final class MoveGenerator {
  static List<ChessMove> generateLegalMoves(Position position) {
    final pseudo = generatePseudoLegalMoves(position);
    final legal = <ChessMove>[];

    for (final move in pseudo) {
      final next = MoveExecutor.apply(position, move);
      if (!AttackDetector.isInCheck(next, position.sideToMove)) {
        legal.add(move);
      }
    }

    return legal;
  }

  static List<ChessMove> generatePseudoLegalMoves(Position position) {
    final moves = <ChessMove>[];
    final us = position.sideToMove;

    for (var i = 0; i < 64; i++) {
      final square = Square.fromIndex(i)!;
      final piece = position.pieceAt(square);
      if (piece == null || piece.color != us) continue;

      switch (piece.type) {
        case PieceType.pawn:
          _generatePawnMoves(position, square, piece, moves);
        case PieceType.knight:
          _generateKnightMoves(position, square, piece, moves);
        case PieceType.bishop:
          _generateSliderMoves(position, square, piece, moves, diagonal: true);
        case PieceType.rook:
          _generateSliderMoves(position, square, piece, moves, diagonal: false);
        case PieceType.queen:
          _generateSliderMoves(position, square, piece, moves, diagonal: true);
          _generateSliderMoves(position, square, piece, moves, diagonal: false);
        case PieceType.king:
          _generateKingMoves(position, square, piece, moves);
      }
    }

    return moves;
  }

  static void _generatePawnMoves(
    Position position,
    Square from,
    Piece piece,
    List<ChessMove> moves,
  ) {
    final direction = piece.color == ChessColor.white ? 1 : -1;
    final startRank = piece.color == ChessColor.white ? 1 : 6;
    final promotionRank = piece.color == ChessColor.white ? 7 : 0;

    final oneForward = from.offset(0, direction);
    if (oneForward != null && position.pieceAt(oneForward) == null) {
      if (oneForward.rank == promotionRank) {
        for (final promo in PieceType.values) {
          if (promo == PieceType.king || promo == PieceType.pawn) continue;
          moves.add(ChessMove(from: from, to: oneForward, promotion: promo));
        }
      } else {
        moves.add(ChessMove(from: from, to: oneForward));

        if (from.rank == startRank) {
          final twoForward = from.offset(0, direction * 2);
          if (twoForward != null && position.pieceAt(twoForward) == null) {
            moves.add(
              ChessMove(
                from: from,
                to: twoForward,
                isDoublePawnPush: true,
              ),
            );
          }
        }
      }
    }

    for (final fileDelta in [-1, 1]) {
      final captureSquare = from.offset(fileDelta, direction);
      if (captureSquare == null) continue;

      final target = position.pieceAt(captureSquare);
      final isEp = position.enPassantSquare == captureSquare;

      if (target?.color == piece.color.opposite || isEp) {
        if (captureSquare.rank == promotionRank) {
          for (final promo in PieceType.values) {
            if (promo == PieceType.king || promo == PieceType.pawn) continue;
            moves.add(
              ChessMove(
                from: from,
                to: captureSquare,
                promotion: promo,
                isCapture: true,
                isEnPassant: isEp,
              ),
            );
          }
        } else {
          moves.add(
            ChessMove(
              from: from,
              to: captureSquare,
              isCapture: true,
              isEnPassant: isEp,
            ),
          );
        }
      }
    }
  }

  static void _generateKnightMoves(
    Position position,
    Square from,
    Piece piece,
    List<ChessMove> moves,
  ) {
    const offsets = [
      [-2, -1],
      [-2, 1],
      [-1, -2],
      [-1, 2],
      [1, -2],
      [1, 2],
      [2, -1],
      [2, 1],
    ];

    for (final offset in offsets) {
      final to = from.offset(offset[0], offset[1]);
      if (to == null) continue;
      final target = position.pieceAt(to);
      if (target == null || target.color != piece.color) {
        moves.add(
          ChessMove(
            from: from,
            to: to,
            isCapture: target != null,
          ),
        );
      }
    }
  }

  static void _generateSliderMoves(
    Position position,
    Square from,
    Piece piece,
    List<ChessMove> moves, {
    required bool diagonal,
  }) {
    final directions = diagonal
        ? const [
            [-1, -1],
            [-1, 1],
            [1, -1],
            [1, 1],
          ]
        : const [
            [-1, 0],
            [1, 0],
            [0, -1],
            [0, 1],
          ];

    for (final dir in directions) {
      var current = from;
      while (true) {
        final next = current.offset(dir[0], dir[1]);
        if (next == null) break;
        current = next;
        final target = position.pieceAt(current);
        if (target == null) {
          moves.add(ChessMove(from: from, to: current));
          continue;
        }
        if (target.color != piece.color) {
          moves.add(ChessMove(from: from, to: current, isCapture: true));
        }
        break;
      }
    }
  }

  static void _generateKingMoves(
    Position position,
    Square from,
    Piece piece,
    List<ChessMove> moves,
  ) {
    for (var fileDelta = -1; fileDelta <= 1; fileDelta++) {
      for (var rankDelta = -1; rankDelta <= 1; rankDelta++) {
        if (fileDelta == 0 && rankDelta == 0) continue;
        final to = from.offset(fileDelta, rankDelta);
        if (to == null) continue;
        final target = position.pieceAt(to);
        if (target == null || target.color != piece.color) {
          moves.add(
            ChessMove(
              from: from,
              to: to,
              isCapture: target != null,
            ),
          );
        }
      }
    }

    _generateCastling(position, from, piece, moves);
  }

  static void _generateCastling(
    Position position,
    Square from,
    Piece piece,
    List<ChessMove> moves,
  ) {
    if (AttackDetector.isInCheck(position, piece.color)) return;

    final rank = piece.color == ChessColor.white ? 0 : 7;
    final kingSquare = Square.fromIndex(4 + rank * 8)!;

    if (from != kingSquare) return;

    final opponent = piece.color.opposite;

    // King side
    if (position.castlingRights.canCastle(piece.color, kingSide: true)) {
      final f = Square.fromIndex(5 + rank * 8)!;
      final g = Square.fromIndex(6 + rank * 8)!;
      if (position.pieceAt(f) == null &&
          position.pieceAt(g) == null &&
          !AttackDetector.isSquareAttacked(position, f, opponent) &&
          !AttackDetector.isSquareAttacked(position, g, opponent)) {
        moves.add(ChessMove(from: from, to: g, isCastle: true));
      }
    }

    // Queen side
    if (position.castlingRights.canCastle(piece.color, kingSide: false)) {
      final b = Square.fromIndex(1 + rank * 8)!;
      final c = Square.fromIndex(2 + rank * 8)!;
      final d = Square.fromIndex(3 + rank * 8)!;
      if (position.pieceAt(b) == null &&
          position.pieceAt(c) == null &&
          position.pieceAt(d) == null &&
          !AttackDetector.isSquareAttacked(position, d, opponent) &&
          !AttackDetector.isSquareAttacked(position, c, opponent)) {
        moves.add(ChessMove(from: from, to: c, isCastle: true));
      }
    }
  }
}
