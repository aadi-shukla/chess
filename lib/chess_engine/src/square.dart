/// Board square index: a1 = 0, h8 = 63 (file + rank * 8).
enum Square {
  a1(0),
  b1(1),
  c1(2),
  d1(3),
  e1(4),
  f1(5),
  g1(6),
  h1(7),
  a2(8),
  b2(9),
  c2(10),
  d2(11),
  e2(12),
  f2(13),
  g2(14),
  h2(15),
  a3(16),
  b3(17),
  c3(18),
  d3(19),
  e3(20),
  f3(21),
  g3(22),
  h3(23),
  a4(24),
  b4(25),
  c4(26),
  d4(27),
  e4(28),
  f4(29),
  g4(30),
  h4(31),
  a5(32),
  b5(33),
  c5(34),
  d5(35),
  e5(36),
  f5(37),
  g5(38),
  h5(39),
  a6(40),
  b6(41),
  c6(42),
  d6(43),
  e6(44),
  f6(45),
  g6(46),
  h6(47),
  a7(48),
  b7(49),
  c7(50),
  d7(51),
  e7(52),
  f7(53),
  g7(54),
  h7(55),
  a8(56),
  b8(57),
  c8(58),
  d8(59),
  e8(60),
  f8(61),
  g8(62),
  h8(63);

  const Square(this.boardIndex);

  final int boardIndex;

  static Square? fromIndex(int index) {
    if (index < 0 || index > 63) return null;
    return Square.values[index];
  }

  static Square? fromAlgebraic(String algebraic) {
    if (algebraic.length != 2) return null;
    final file = algebraic.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = algebraic.codeUnitAt(1) - '1'.codeUnitAt(0);
    if (file < 0 || file > 7 || rank < 0 || rank > 7) return null;
    return fromIndex(file + rank * 8);
  }

  int get file => boardIndex % 8;
  int get rank => boardIndex ~/ 8;

  String get algebraic {
    final fileChar = String.fromCharCode('a'.codeUnitAt(0) + file);
    return '$fileChar${rank + 1}';
  }

  Square? offset(int fileDelta, int rankDelta) {
    final newFile = file + fileDelta;
    final newRank = rank + rankDelta;
    if (newFile < 0 || newFile > 7 || newRank < 0 || newRank > 7) {
      return null;
    }
    return Square.values[newFile + newRank * 8];
  }
}
