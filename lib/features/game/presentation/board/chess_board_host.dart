import 'package:chess/chess_engine/chess_engine.dart';
import 'package:chess/features/game/domain/entities/board_theme.dart';

/// Shared board interaction contract for offline and online game controllers.
abstract class ChessBoardHost {
  Position get position;
  BoardTheme get boardTheme;
  ChessMove? get lastMove;
  bool get boardFlipped;
  List<Square> get legalTargets;
  Square? get selectedSquare;

  void onSquareTap(Square square);
  bool isSquareHighlighted(Square square);
  bool isSquareInCheck(Square square);
}

/// Promotion flow shared by offline and online controllers.
abstract class PromotionHost {
  Position get position;
  void completePromotion(PieceType piece);
  void cancelPromotion();
}
