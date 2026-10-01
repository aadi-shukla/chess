import 'package:chess/chess_engine/src/piece.dart';

/// Castling availability flags (white K/Q, black K/Q).
class CastlingRights {
  const CastlingRights({
    this.whiteKingSide = true,
    this.whiteQueenSide = true,
    this.blackKingSide = true,
    this.blackQueenSide = true,
  });

  const CastlingRights.none()
      : whiteKingSide = false,
        whiteQueenSide = false,
        blackKingSide = false,
        blackQueenSide = false;

  final bool whiteKingSide;
  final bool whiteQueenSide;
  final bool blackKingSide;
  final bool blackQueenSide;

  bool canCastle(ChessColor color, {required bool kingSide}) {
    return switch (color) {
      ChessColor.white => kingSide ? whiteKingSide : whiteQueenSide,
      ChessColor.black => kingSide ? blackKingSide : blackQueenSide,
    };
  }

  CastlingRights without(ChessColor color, {required bool kingSide}) {
    return CastlingRights(
      whiteKingSide: !(color == ChessColor.white && kingSide) && whiteKingSide,
      whiteQueenSide:
          !(color == ChessColor.white && !kingSide) && whiteQueenSide,
      blackKingSide: !(color == ChessColor.black && kingSide) && blackKingSide,
      blackQueenSide:
          !(color == ChessColor.black && !kingSide) && blackQueenSide,
    );
  }

  CastlingRights revokeColor(ChessColor color) {
    return color == ChessColor.white
        ? CastlingRights(
            whiteKingSide: false,
            whiteQueenSide: false,
            blackKingSide: blackKingSide,
            blackQueenSide: blackQueenSide,
          )
        : CastlingRights(
            whiteKingSide: whiteKingSide,
            whiteQueenSide: whiteQueenSide,
            blackKingSide: false,
            blackQueenSide: false,
          );
  }

  String get fen {
    final buffer = StringBuffer();
    if (whiteKingSide) buffer.write('K');
    if (whiteQueenSide) buffer.write('Q');
    if (blackKingSide) buffer.write('k');
    if (blackQueenSide) buffer.write('q');
    return buffer.isEmpty ? '-' : buffer.toString();
  }

  static CastlingRights fromFen(String fen) {
    if (fen == '-') return const CastlingRights.none();
    return CastlingRights(
      whiteKingSide: fen.contains('K'),
      whiteQueenSide: fen.contains('Q'),
      blackKingSide: fen.contains('k'),
      blackQueenSide: fen.contains('q'),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CastlingRights &&
      other.whiteKingSide == whiteKingSide &&
      other.whiteQueenSide == whiteQueenSide &&
      other.blackKingSide == blackKingSide &&
      other.blackQueenSide == blackQueenSide;

  @override
  int get hashCode =>
      Object.hash(whiteKingSide, whiteQueenSide, blackKingSide, blackQueenSide);
}
