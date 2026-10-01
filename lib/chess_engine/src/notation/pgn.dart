import 'package:chess/chess_engine/src/notation/fen.dart';
import 'package:chess/chess_engine/src/piece.dart';

/// Portable Game Notation export.
abstract final class PgnExporter {
  static String export({
    required List<String> moveSans,
    String event = 'Casual Game',
    String site = 'Chess App',
    String? white = 'White',
    String? black = 'Black',
    String result = '*',
    DateTime? date,
  }) {
    final playedOn = date ?? DateTime.now();
    final dateStr =
        '${playedOn.year}.${playedOn.month.toString().padLeft(2, '0')}.${playedOn.day.toString().padLeft(2, '0')}';

    final buffer = StringBuffer()
      ..writeln('[Event "$event"]')
      ..writeln('[Site "$site"]')
      ..writeln('[Date "$dateStr"]')
      ..writeln('[White "${white ?? '?'}"]')
      ..writeln('[Black "${black ?? '?'}"]')
      ..writeln('[Result "$result"]')
      ..writeln('[FEN "${FenParser.startingFen}"]')
      ..writeln('[SetUp "1"]')
      ..writeln();

    for (var i = 0; i < moveSans.length; i++) {
      if (i.isEven) {
        buffer.write('${i ~/ 2 + 1}. ${moveSans[i]}');
      } else {
        buffer.write(' ${moveSans[i]}');
      }
      if (i.isOdd) buffer.writeln();
    }

    if (moveSans.length.isOdd) buffer.writeln();
    buffer.write(result);
    return buffer.toString();
  }

  static String resultFromOutcome({
    required bool isCheckmate,
    required bool isStalemate,
    required bool isDraw,
    required ChessColor sideToMove,
  }) {
    if (isDraw || isStalemate) return '1/2-1/2';
    if (isCheckmate) {
      return sideToMove == ChessColor.white ? '0-1' : '1-0';
    }
    return '*';
  }
}
