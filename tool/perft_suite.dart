import 'package:chess/chess_engine/chess_engine.dart';

void main() {
  const positions = <String, List<int>>{
    'start': [
      20,
      400,
      8902,
      197281,
    ],
    'kiwipete': [
      48,
      2039,
      97862,
    ],
    'position3': [
      14,
      191,
      2812,
      43238,
    ],
    'position4': [
      6,
      264,
      9467,
      422333,
    ],
    'position5': [
      44,
      1486,
      62379,
    ],
    'position6': [
      46,
      2079,
      89890,
    ],
  };

  const fens = {
    'start': FenParser.startingFen,
    'kiwipete':
        'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1',
    'position3': '8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1',
    'position4':
        'r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1',
    'position5': 'rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8',
    'position6':
        'r4rk1/1pp1qppp/p1np1n2/2b1p1B1/2B1P1b1/P1NP1N2/1PP1QPPP/R4RK1 w - - 0 10',
  };

  for (final entry in positions.entries) {
    final position = FenParser.fromFen(fens[entry.key]!);
    for (var d = 0; d < entry.value.length; d++) {
      final depth = d + 1;
      final expected = entry.value[d];
      final actual = perft(position, depth);
      final ok = actual == expected ? 'OK' : 'FAIL';
      // ignore: avoid_print
      print('$ok ${entry.key} depth $depth: expected $expected got $actual');
    }
  }
}
