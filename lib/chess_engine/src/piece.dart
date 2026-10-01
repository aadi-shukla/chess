/// Side to move.
enum ChessColor {
  white,
  black;

  ChessColor get opposite => this == ChessColor.white ? ChessColor.black : ChessColor.white;
}

/// Piece type identifiers.
enum PieceType {
  pawn,
  knight,
  bishop,
  rook,
  queen,
  king;

  String get fenChar => switch (this) {
        PieceType.pawn => 'p',
        PieceType.knight => 'n',
        PieceType.bishop => 'b',
        PieceType.rook => 'r',
        PieceType.queen => 'q',
        PieceType.king => 'k',
      };
}

/// A colored chess piece.
class Piece {
  const Piece({required this.color, required this.type});

  final ChessColor color;
  final PieceType type;

  String get fenChar {
    final char = type.fenChar;
    return color == ChessColor.white ? char.toUpperCase() : char;
  }

  static Piece? fromFenChar(String char) {
    if (char.isEmpty) return null;
    final lower = char.toLowerCase();
    final type = switch (lower) {
      'p' => PieceType.pawn,
      'n' => PieceType.knight,
      'b' => PieceType.bishop,
      'r' => PieceType.rook,
      'q' => PieceType.queen,
      'k' => PieceType.king,
      _ => null,
    };
    if (type == null) return null;
    final color = char == lower ? ChessColor.black : ChessColor.white;
    return Piece(color: color, type: type);
  }

  @override
  bool operator ==(Object other) =>
      other is Piece && other.color == color && other.type == type;

  @override
  int get hashCode => Object.hash(color, type);

  @override
  String toString() => '${color.name} ${type.name}';
}
