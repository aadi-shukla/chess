import 'package:chess/chess_engine/src/piece.dart';
import 'package:chess/chess_engine/src/square.dart';

/// A chess move with optional promotion and special-move flags.
class ChessMove {
  const ChessMove({
    required this.from,
    required this.to,
    this.promotion = PieceType.queen,
    this.isCapture = false,
    this.isEnPassant = false,
    this.isCastle = false,
    this.isDoublePawnPush = false,
  });

  final Square from;
  final Square to;
  final PieceType promotion;
  final bool isCapture;
  final bool isEnPassant;
  final bool isCastle;
  final bool isDoublePawnPush;

  String get uci => '${from.algebraic}${to.algebraic}'
      '${promotion != PieceType.queen && _isPromotionMove ? promotion.fenChar : ''}';

  bool get _isPromotionMove {
    final rankDelta = (to.rank - from.rank).abs();
    return rankDelta == 1 && (from.rank == 1 || from.rank == 6);
  }

  @override
  bool operator ==(Object other) =>
      other is ChessMove &&
      other.from == from &&
      other.to == to &&
      other.promotion == promotion &&
      other.isEnPassant == isEnPassant &&
      other.isCastle == isCastle;

  @override
  int get hashCode => Object.hash(from, to, promotion, isEnPassant, isCastle);

  @override
  String toString() => uci;
}
