import 'package:chess/chess_engine/chess_engine.dart';

void main(List<String> args) {
  const kiwipete =
      'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1';
  final depth = args.isNotEmpty ? int.parse(args.first) : 2;
  final fen = args.length > 1 ? args.sublist(1).join(' ') : kiwipete;
  final position = FenParser.fromFen(fen);
  var total = 0;
  for (final move in MoveGenerator.generateLegalMoves(position)) {
    final child = MoveExecutor.apply(position, move);
    final count = perft(child, depth - 1);
    total += count;
    // ignore: avoid_print
    print('${move.uci}: $count');
  }
  // ignore: avoid_print
  print('total: $total');
}
