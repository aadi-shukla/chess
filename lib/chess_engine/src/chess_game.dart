import 'package:chess/chess_engine/src/game_status.dart';
import 'package:chess/chess_engine/src/move.dart';
import 'package:chess/chess_engine/src/move_executor.dart';
import 'package:chess/chess_engine/src/move_generator.dart';
import 'package:chess/chess_engine/src/notation/fen.dart';
import 'package:chess/chess_engine/src/notation/pgn.dart';
import 'package:chess/chess_engine/src/notation/san.dart';
import 'package:chess/chess_engine/src/piece.dart';
import 'package:chess/chess_engine/src/position.dart';
import 'package:chess/chess_engine/src/square.dart';
import 'package:chess/chess_engine/src/timer/chess_clock.dart';

/// Record of a single move in game history.
class HistoryEntry {
  const HistoryEntry({
    required this.positionBefore,
    required this.move,
    required this.san,
    required this.fenAfter,
    this.clockSnapshot,
  });

  final Position positionBefore;
  final ChessMove move;
  final String san;
  final String fenAfter;
  final ChessClock? clockSnapshot;
}

/// Complete chess game session with undo/redo, clocks, and notation.
class ChessGame {
  ChessGame({
    Position? initialPosition,
    ChessClock? initialClock,
  })  : _positions = [
          initialPosition ?? FenParser.fromFen(FenParser.startingFen),
        ],
        _historyIndex = 0,
        _moves = [],
        _sans = [],
        clock = initialClock ?? ChessClock() {
    _recordRepetition(_currentPosition);
    clock.start(_currentPosition.sideToMove);
  }

  final List<Position> _positions;
  final List<ChessMove> _moves;
  final List<String> _sans;
  final Map<String, int> _repetitionCounts = {};
  final ChessClock clock;

  int _historyIndex;

  Position get position => _positions[_historyIndex];
  Position get _currentPosition => position;

  List<ChessMove> get moves => List.unmodifiable(_moves);
  List<String> get sans => List.unmodifiable(_sans);
  bool get canUndo => _historyIndex > 0;
  bool get canRedo => _historyIndex < _moves.length;

  GameStatus get status => GameStatus.analyze(
        _currentPosition,
        repetitionCounts: _repetitionCounts,
      );

  String get fen => FenParser.toFen(_currentPosition);

  List<ChessMove> get legalMoves => MoveGenerator.generateLegalMoves(_currentPosition);

  List<ChessMove> legalMovesFrom(Square? square) {
    final all = legalMoves;
    if (square == null) return all;
    return all.where((m) => m.from == square).toList();
  }

  bool isLegalMove(ChessMove move) {
    return legalMoves.any(
      (m) =>
          m.from == move.from &&
          m.to == move.to &&
          m.promotion == move.promotion,
    );
  }

  /// Applies [move] if legal. Returns false if rejected.
  bool makeMove(ChessMove move) {
    if (!isLegalMove(move)) return false;
    if (status.isGameOver) return false;

    final san = SanConverter.toSan(_currentPosition, move);
    final next = MoveExecutor.apply(_currentPosition, move);

    // Truncate redo branch
    if (_historyIndex < _moves.length) {
      _moves.removeRange(_historyIndex, _moves.length);
      _sans.removeRange(_historyIndex, _sans.length);
      _positions.removeRange(_historyIndex + 1, _positions.length);
    }

    _moves.add(move);
    _sans.add(san);
    _positions.add(next);
    _historyIndex++;

    _recordRepetition(next);
    clock.switchTurn(next.sideToMove);

    return true;
  }

  bool makeMoveFromUci(String uci, {PieceType promotion = PieceType.queen}) {
    if (uci.length < 4) return false;
    final from = Square.fromAlgebraic(uci.substring(0, 2));
    final to = Square.fromAlgebraic(uci.substring(2, 4));
    if (from == null || to == null) return false;

  final promoChar = uci.length > 4 ? uci[4] : null;
    final promo = promoChar != null
        ? Piece.fromFenChar(promoChar)?.type ?? promotion
        : promotion;

    final matching = legalMoves.where((m) => m.from == from && m.to == to);
    if (matching.isEmpty) return false;

    final move = matching.firstWhere(
      (m) => m.promotion == promo,
      orElse: () => matching.first,
    );

    return makeMove(move);
  }

  bool undo() {
    if (!canUndo) return false;
    clock.switchTurn(_currentPosition.sideToMove.opposite);
    _historyIndex--;
    _decrementRepetition(_positions[_historyIndex + 1]);
    return true;
  }

  bool redo() {
    if (!canRedo) return false;
    _historyIndex++;
    _recordRepetition(_currentPosition);
    clock.switchTurn(_currentPosition.sideToMove);
    return true;
  }

  String exportPgn({
    String white = 'White',
    String black = 'Black',
  }) {
    final st = status;
    final result = PgnExporter.resultFromOutcome(
      isCheckmate: st.outcome == GameOutcome.checkmate,
      isStalemate: st.outcome == GameOutcome.stalemate,
      isDraw: st.isDraw,
      sideToMove: _currentPosition.sideToMove,
    );

    return PgnExporter.export(
      moveSans: _sans,
      white: white,
      black: black,
      result: result,
    );
  }

  void _recordRepetition(Position position) {
    final key = position.repetitionKey;
    _repetitionCounts[key] = (_repetitionCounts[key] ?? 0) + 1;
  }

  void _decrementRepetition(Position position) {
    final key = position.repetitionKey;
    final count = (_repetitionCounts[key] ?? 1) - 1;
    if (count <= 0) {
      _repetitionCounts.remove(key);
    } else {
      _repetitionCounts[key] = count;
    }
  }
}

/// Perft (performance test) for move generation validation.
int perft(Position position, int depth) {
  if (depth == 0) return 1;
  var nodes = 0;
  for (final move in MoveGenerator.generateLegalMoves(position)) {
    nodes += perft(MoveExecutor.apply(position, move), depth - 1);
  }
  return nodes;
}

int divide(Position position, int depth) {
  var total = 0;
  for (final move in MoveGenerator.generateLegalMoves(position)) {
    final count = perft(MoveExecutor.apply(position, move), depth - 1);
    total += count;
  }
  return total;
}
