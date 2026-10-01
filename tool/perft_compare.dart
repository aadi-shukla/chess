import 'package:chess/chess_engine/chess_engine.dart';

/// Reference perft(2) counts per root move for Kiwipete (depth-2 divide).
const kiwipeteDivideDepth2 = <String, int>{
  'a1b1': 1971,
  'a1c1': 1970,
  'a1d1': 1887,
  'e1d1': 1894,
  'e1f1': 1897,
  'e1g1': 2059,
  'e1c1': 1887,
  'h1g1': 2014,
  'h1f1': 1929,
  'a2a3': 2188,
  'a2a4': 2153,
  'b2b3': 1966,
  'd2c1': 1966,
  'd2e3': 2139,
  'd2f4': 2003,
  'd2g5': 2137,
  'd2h6': 2022,
  'e2d1': 1733,
  'e2d3': 2052,
  'e2c4': 2084,
  'e2b5': 2059,
  'e2a6': 1909,
  'e2f1': 2060,
  'g2g3': 1882,
  'g2g4': 1843,
  'g2h3': 1970,
  'c3a4': 2205,
  'c3b1': 2040,
  'c3b5': 2140,
  'c3d1': 2042,
  'f3g4': 2171,
  'f3h5': 2269,
  'f3e3': 2176,
  'f3d3': 2007,
  'f3g3': 2216,
  'f3h3': 2360,
  'f3f4': 2134,
  'f3f5': 2398,
  'f3f6': 2113,
  'd5d6': 1993,
  'd5e6': 2243,
  'e5c4': 1882,
  'e5c6': 2029,
  'e5d3': 1805,
  'e5d7': 2126,
  'e5f7': 2082,
  'e5g4': 1880,
  'e5g6': 1999,
};

void main() {
  const fen =
      'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1';
  final position = FenParser.fromFen(fen);
  var total = 0;
  var mismatches = 0;

  for (final move in MoveGenerator.generateLegalMoves(position)) {
    final child = MoveExecutor.apply(position, move);
    final count = perft(child, 2);
    total += count;
    final expected = kiwipeteDivideDepth2[move.uci];
    if (expected != null && expected != count) {
      mismatches++;
      // ignore: avoid_print
      print('MISMATCH ${move.uci}: expected $expected, got $count');
    } else if (expected == null) {
      // ignore: avoid_print
      print('UNKNOWN ${move.uci}: $count');
    }
  }
  // ignore: avoid_print
  print('total: $total mismatches: $mismatches');
}
