import 'package:chess/chess_engine/src/chess_game.dart';
import 'package:chess/chess_engine/src/notation/fen.dart';
import 'package:chess/chess_engine/src/piece.dart';
import 'package:chess/chess_engine/src/timer/chess_clock.dart';

/// Serializable snapshot of an in-progress [ChessGame].
class ChessGameSnapshot {
  const ChessGameSnapshot({
    required this.moveUcis,
    required this.whiteMillis,
    required this.blackMillis,
    required this.incrementMillis,
    this.activeColor,
  });

  factory ChessGameSnapshot.fromJson(Map<String, dynamic> json) {
    final colorName = json['activeColor'] as String?;
    return ChessGameSnapshot(
      moveUcis: (json['moveUcis'] as List<dynamic>).cast<String>(),
      whiteMillis: json['whiteMillis'] as int,
      blackMillis: json['blackMillis'] as int,
      incrementMillis: json['incrementMillis'] as int? ?? 0,
      activeColor: colorName == null
          ? null
          : ChessColor.values.byName(colorName),
    );
  }

  final List<String> moveUcis;
  final int whiteMillis;
  final int blackMillis;
  final int incrementMillis;
  final ChessColor? activeColor;

  Map<String, dynamic> toJson() => {
        'moveUcis': moveUcis,
        'whiteMillis': whiteMillis,
        'blackMillis': blackMillis,
        'incrementMillis': incrementMillis,
        'activeColor': activeColor?.name,
      };
}

/// Helpers for persisting and restoring [ChessGame] sessions.
abstract final class ChessGamePersistence {
  static ChessGameSnapshot capture(ChessGame game) {
    return ChessGameSnapshot(
      moveUcis: game.moves.map((m) => m.uci).toList(),
      whiteMillis: game.clock.whiteMillis,
      blackMillis: game.clock.blackMillis,
      incrementMillis: game.clock.incrementMillis,
      activeColor: game.clock.activeColor,
    );
  }

  static ChessGame restore(ChessGameSnapshot snapshot) {
    final millis = snapshot.whiteMillis > snapshot.blackMillis
        ? snapshot.whiteMillis
        : snapshot.blackMillis;
    final game = ChessGame(
      initialClock: ChessClock(
        whiteMillis: snapshot.whiteMillis > 0 ? snapshot.whiteMillis : millis,
        blackMillis: snapshot.blackMillis > 0 ? snapshot.blackMillis : millis,
        incrementMillis: snapshot.incrementMillis,
        activeColor: snapshot.activeColor,
      ),
    );

    for (final uci in snapshot.moveUcis) {
      game.makeMoveFromUci(uci);
    }

    game.clock.whiteMillis = snapshot.whiteMillis;
    game.clock.blackMillis = snapshot.blackMillis;

    if (snapshot.activeColor != null && !game.status.isGameOver) {
      game.clock.start(snapshot.activeColor!);
    } else if (game.status.isGameOver) {
      game.clock.stop();
    }

    return game;
  }

  static String currentFen(ChessGame game) => FenParser.toFen(game.position);
}
