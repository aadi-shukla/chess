import 'package:chess/chess_engine/chess_engine.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Resolves piece sprite paths under [assets/pieces/].
abstract final class ChessPieceAssets {
  static String pathFor(Piece piece) {
    final color = piece.color == ChessColor.white ? 'w' : 'b';
    return 'assets/pieces/$color${piece.type.fenChar.toUpperCase()}.png';
  }

  static const all = [
    'assets/pieces/wK.png',
    'assets/pieces/wQ.png',
    'assets/pieces/wR.png',
    'assets/pieces/wB.png',
    'assets/pieces/wN.png',
    'assets/pieces/wP.png',
    'assets/pieces/bK.png',
    'assets/pieces/bQ.png',
    'assets/pieces/bR.png',
    'assets/pieces/bB.png',
    'assets/pieces/bN.png',
    'assets/pieces/bP.png',
  ];
}

/// Unicode chess piece glyphs used when sprites are unavailable.
abstract final class ChessPieceGlyphs {
  static const Map<String, String> _glyphs = {
    'wK': '♔',
    'wQ': '♕',
    'wR': '♖',
    'wB': '♗',
    'wN': '♘',
    'wP': '♙',
    'bK': '♚',
    'bQ': '♛',
    'bR': '♜',
    'bB': '♝',
    'bN': '♞',
    'bP': '♟',
  };

  static String forPiece(Piece piece) {
    final key =
        '${piece.color == ChessColor.white ? 'w' : 'b'}${piece.type.fenChar.toUpperCase()}';
    return _glyphs[key] ?? '?';
  }
}

/// Renders a single chess piece scaled to fit its square.
class ChessPieceWidget extends StatelessWidget {
  const ChessPieceWidget({
    required this.piece,
    this.size = 44,
    super.key,
  });

  final Piece piece;
  final double size;

  static const _pieceScale = 0.88;

  @override
  Widget build(BuildContext context) {
    final pieceSize = size * _pieceScale;

    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Image.asset(
          ChessPieceAssets.pathFor(piece),
          width: pieceSize,
          height: pieceSize,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _GlyphFallback(
            piece: piece,
            size: pieceSize,
          ),
        ),
      ),
    );
  }
}

class _GlyphFallback extends StatelessWidget {
  const _GlyphFallback({
    required this.piece,
    required this.size,
  });

  final Piece piece;
  final double size;

  @override
  Widget build(BuildContext context) {
    final glyph = ChessPieceGlyphs.forPiece(piece);
    final isWhite = piece.color == ChessColor.white;
    final fontSize = size * 0.95;
    final strokeWidth = fontSize * 0.05;
    final fillColor = isWhite ? const Color(0xFFFFFFFF) : const Color(0xFF111111);
    final strokeColor = isWhite ? const Color(0xFF1F1F1F) : const Color(0xFFF0F0F0);
    final textStyle = GoogleFonts.notoSansSymbols2(
      fontSize: fontSize,
      height: 1,
      fontWeight: FontWeight.w500,
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          glyph,
          style: textStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..color = strokeColor,
          ),
        ),
        Text(glyph, style: textStyle.copyWith(color: fillColor)),
      ],
    );
  }
}

/// Warms the piece sprite cache before the first frame is drawn.
Future<void> precacheChessPieces(BuildContext context) {
  return Future.wait(
    ChessPieceAssets.all.map(
      (path) => precacheImage(AssetImage(path), context),
    ),
  );
}
