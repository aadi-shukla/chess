import 'dart:async';

import 'package:chess/chess_engine/chess_engine.dart';
import 'package:chess/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:chess/features/game/domain/entities/board_theme.dart';
import 'package:chess/features/game/domain/entities/game_config.dart';
import 'package:chess/features/game/domain/entities/game_history_entry.dart';
import 'package:chess/features/game/domain/entities/game_launch_args.dart';
import 'package:chess/features/game/domain/entities/game_mode.dart';
import 'package:chess/features/game/domain/entities/game_statistics.dart';
import 'package:chess/features/game/domain/entities/saved_game.dart';
import 'package:chess/features/game/domain/repositories/game_repository.dart';
import 'package:chess/features/game/presentation/board/chess_board_host.dart';
import 'package:chess/features/game/presentation/controllers/play_tab_controller.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

/// Controls an offline chess session (PvP or PvAI) with save and stats.
class OfflineGameController extends GetxController
    implements ChessBoardHost, PromotionHost {
  OfflineGameController(this._repository);

  static const boardId = 'board';
  static const clockId = 'clock';
  static const movesId = 'moves';
  static const chromeId = 'chrome';

  final GameRepository _repository;

  late GameConfig config;
  late ChessGame game;
  @override
  BoardTheme boardTheme = BoardTheme.classic;

  @override
  Square? selectedSquare;
  @override
  List<Square> legalTargets = [];
  @override
  ChessMove? lastMove;
  @override
  bool boardFlipped = false;
  Square? pendingPromotionFrom;
  Square? pendingPromotionTo;

  Timer? _clockTimer;
  Timer? _persistDebounce;
  String? statusMessage;
  bool isAiThinking = false;
  bool _statsRecorded = false;
  bool _gameOverDialogShown = false;
  bool hapticsEnabled = true;
  bool autoSaveEnabled = true;

  final whiteMillisRx = 0.obs;
  final blackMillisRx = 0.obs;

  String get savedGameId => _savedGameId;
  String _savedGameId = const Uuid().v4();

  @override
  void onInit() {
    super.onInit();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    final args = Get.arguments;
    boardTheme = await _repository.loadBoardTheme();
    hapticsEnabled = await _repository.loadHapticsEnabled();
    autoSaveEnabled = await _repository.loadAutoSaveEnabled();

    if (args is GameLaunchArgs) {
      config = args.config;
      boardTheme = config.boardTheme;
      if (args.resume != null) {
        _savedGameId = args.resume!.id;
        _restoreFromSaved(args.resume!);
      } else {
        await _repository.clearSavedGame();
        _startNewGame();
      }
    } else if (args is GameConfig) {
      config = args;
      _startNewGame();
    } else {
      config = const GameConfig();
      _startNewGame();
    }

    _startClockTimer();
    _bindSyncUid();
    if (config.isVsAi && _isAiTurn) {
      unawaited(_playAiMove());
    }
    _refreshAll();
  }

  void _refreshAll() => update([boardId, clockId, movesId, chromeId]);

  void _refreshBoard() => update([boardId, clockId]);

  void _refreshChrome() => update([chromeId]);

  @override
  void onClose() {
    _clockTimer?.cancel();
    _persistDebounce?.cancel();
    if (autoSaveEnabled && !isGameOver) {
      unawaited(_persistGame());
    }
    unawaited(_refreshPlayTab());
    super.onClose();
  }

  @override
  Position get position => game.position;
  GameStatus get status => game.status;
  List<String> get moveHistory => game.sans;
  bool get canUndo => game.canUndo && !isAiThinking;
  bool get canRedo => game.canRedo && !isAiThinking;
  String get fen => game.fen;

  int get whiteMillis => whiteMillisRx.value;
  int get blackMillis => blackMillisRx.value;

  bool get isGameOver =>
      status.isGameOver || game.clock.expiredColor != null;

  bool get shouldShowGameOverDialog =>
      isGameOver && statusMessage != null && !_gameOverDialogShown;

  void markGameOverDialogShown() => _gameOverDialogShown = true;

  bool get isVsAi => config.isVsAi;
  ChessColor get humanColor => config.humanColor;
  bool get _isAiTurn =>
      config.isVsAi && position.sideToMove != config.humanColor;

  void _startNewGame() {
    final millis = config.minutes * 60 * 1000;
    game = ChessGame(
      initialClock: ChessClock(
        whiteMillis: millis,
        blackMillis: millis,
        incrementMillis: config.incrementSeconds * 1000,
      ),
    );
    _savedGameId = const Uuid().v4();
    _resetUiState();
    boardFlipped = config.isVsAi && config.humanColor == ChessColor.black;
  }

  void _restoreFromSaved(SavedGame saved) {
    config = GameConfig(
      mode: saved.mode,
      minutes: config.minutes,
      incrementSeconds: saved.snapshot.incrementMillis ~/ 1000,
      aiDifficulty: saved.aiDifficulty,
      humanColor: saved.humanColor,
      boardTheme: boardTheme,
    );
    game = ChessGamePersistence.restore(saved.snapshot);
    _resetUiState();
    boardFlipped = config.isVsAi && config.humanColor == ChessColor.black;
    if (game.status.isGameOver) {
      _updateStatusMessage();
      _refreshAll();
    }
  }

  void _resetUiState() {
    _clearSelection();
    lastMove = game.moves.isEmpty ? null : game.moves.last;
    statusMessage = null;
    _statsRecorded = false;
    isAiThinking = false;
    _gameOverDialogShown = false;
  }

  void _startClockTimer() {
    _clockTimer?.cancel();
    _syncClockObservables();
    _clockTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (game.clock.expiredColor != null && statusMessage == null) {
        final loser = game.clock.expiredColor!;
        statusMessage = _timeoutMessage(loser);
        game.clock.stop();
        _persistDebounce?.cancel();
        unawaited(_onGameFinished());
        _refreshAll();
      }
      _syncClockObservables();
    });
  }

  void _syncClockObservables() {
    whiteMillisRx.value = game.clock.millisFor(ChessColor.white);
    blackMillisRx.value = game.clock.millisFor(ChessColor.black);
  }

  Future<void> newGame() async {
    await _repository.clearSavedGame();
    _startNewGame();
    _startClockTimer();
    if (config.isVsAi && _isAiTurn) {
      await _playAiMove();
    }
    _refreshAll();
  }

  void toggleBoardFlip() {
    boardFlipped = !boardFlipped;
    _refreshBoard();
  }

  @override
  void onSquareTap(Square square) {
    if (isGameOver || isAiThinking || pendingPromotionFrom != null) return;

    if (config.isVsAi && position.sideToMove != config.humanColor) return;

    final piece = position.pieceAt(square);
    final isOwnPiece =
        piece != null && piece.color == position.sideToMove;

    if (selectedSquare == square) {
      _clearSelection();
      _refreshBoard();
      return;
    }

    if (selectedSquare != null && legalTargets.contains(square)) {
      _attemptMove(selectedSquare!, square);
      return;
    }

    if (isOwnPiece) {
      selectedSquare = square;
      legalTargets = game
          .legalMovesFrom(square)
          .map((m) => m.to)
          .toSet()
          .toList();
      _refreshBoard();
      return;
    }

    _clearSelection();
    _refreshBoard();
  }

  void _attemptMove(Square from, Square to) {
    final candidates =
        game.legalMovesFrom(from).where((m) => m.to == to).toList();
    if (candidates.isEmpty) return;

    if (candidates.length > 1) {
      pendingPromotionFrom = from;
      pendingPromotionTo = to;
      _refreshAll();
      return;
    }

    _applyMove(candidates.first);
  }

  @override
  void completePromotion(PieceType piece) {
    final from = pendingPromotionFrom;
    final to = pendingPromotionTo;
    if (from == null || to == null) return;

    final move = game.legalMovesFrom(from).firstWhere(
          (m) => m.to == to && m.promotion == piece,
        );
    pendingPromotionFrom = null;
    pendingPromotionTo = null;
    _applyMove(move);
  }

  @override
  void cancelPromotion() {
    pendingPromotionFrom = null;
    pendingPromotionTo = null;
    _clearSelection();
    _refreshBoard();
  }

  Future<void> _applyMove(ChessMove move) async {
    if (!game.makeMove(move)) return;
    lastMove = move;
    _clearSelection();
    _updateStatusMessage();
    if (hapticsEnabled) {
      await HapticFeedback.lightImpact();
    }
    _refreshAll();

    if (isGameOver) {
      await _onGameFinished();
      return;
    }

    if (autoSaveEnabled) {
      _schedulePersist();
    }

    if (config.isVsAi && _isAiTurn) {
      await _playAiMove();
    }
  }

  Future<void> _playAiMove() async {
    if (isGameOver || !_isAiTurn || pendingPromotionFrom != null) return;

    isAiThinking = true;
    _refreshChrome();

    try {
      await Future<void>.delayed(const Duration(milliseconds: 350));

      if (isGameOver || !_isAiTurn || pendingPromotionFrom != null) return;

      final aiMove = ChessAi.findBestMove(
        position,
        position.sideToMove,
        difficulty: config.aiDifficulty,
      );

      if (aiMove != null && !isGameOver) {
        await _applyMove(aiMove);
      } else {
        _updateStatusMessage();
        _refreshAll();
      }
    } finally {
      isAiThinking = false;
      _refreshChrome();
    }
  }

  Future<void> undo() async {
    if (!game.canUndo || isAiThinking) return;

    if (config.isVsAi) {
      if (game.canUndo) game.undo();
      if (game.canUndo && position.sideToMove != config.humanColor) {
        game.undo();
      }
    } else {
      game.undo();
    }

    lastMove = game.moves.isEmpty ? null : game.moves.last;
    statusMessage = game.status.isGameOver ? statusMessage : null;
    _statsRecorded = false;
    _clearSelection();
    if (autoSaveEnabled) _schedulePersist();
    _refreshAll();
  }

  Future<void> redo() async {
    if (!game.canRedo || isAiThinking) return;
    game.redo();
    lastMove = game.moves.isEmpty ? null : game.moves.last;
    _updateStatusMessage();
    if (autoSaveEnabled) _schedulePersist();
    _refreshAll();
  }

  void _schedulePersist() {
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(seconds: 2), () {
      unawaited(_persistGame());
    });
  }

  Future<void> _persistGame() async {
    if (isGameOver) {
      await _repository.clearSavedGame();
      return;
    }

    final saved = SavedGame(
      id: _savedGameId,
      mode: config.mode,
      snapshot: ChessGamePersistence.capture(game),
      savedAt: DateTime.now(),
      aiDifficulty: config.aiDifficulty,
      humanColor: config.humanColor,
      moveCount: game.moves.length,
    );
    await _repository.saveGame(saved);
  }

  void _bindSyncUid() {
    if (!Get.isRegistered<AuthSessionController>()) return;
    final uid = Get.find<AuthSessionController>().user.value?.uid;
    _repository.setSyncUid(uid);
  }

  Future<void> _onGameFinished() async {
    if (_statsRecorded) return;
    _statsRecorded = true;
    game.clock.stop();
    _persistDebounce?.cancel();
    await _recordHistory();
    await _repository.clearSavedGame();
    await _recordStatistics();
    await _refreshPlayTab();
  }

  Future<void> _refreshPlayTab() async {
    if (Get.isRegistered<PlayTabController>()) {
      await Get.find<PlayTabController>().reload();
    }
  }

  Future<void> _recordHistory() async {
    final outcome = _resolveOutcome();
    final result = switch (outcome) {
      _GameResult.whiteWin => 'white_win',
      _GameResult.blackWin => 'black_win',
      _GameResult.draw => 'draw',
    };
    await _repository.recordHistory(
      GameHistoryEntry(
        id: _savedGameId,
        mode: config.mode,
        result: result,
        moveCount: game.moves.length,
        completedAt: DateTime.now(),
        moveSans: game.sans,
      ),
    );
  }

  Future<void> _recordStatistics() async {
    final stats = await _repository.loadStatistics();
    final outcome = _resolveOutcome();

    GameStatistics updated;
    if (config.mode == GameMode.playerVsPlayer) {
      updated = switch (outcome) {
        _GameResult.whiteWin => stats.copyWith(
            pvpGames: stats.pvpGames + 1,
            pvpWhiteWins: stats.pvpWhiteWins + 1,
          ),
        _GameResult.blackWin => stats.copyWith(
            pvpGames: stats.pvpGames + 1,
            pvpBlackWins: stats.pvpBlackWins + 1,
          ),
        _ => stats.copyWith(
            pvpGames: stats.pvpGames + 1,
            pvpDraws: stats.pvpDraws + 1,
          ),
      };
    } else {
      updated = switch (outcome) {
        _GameResult.whiteWin => stats.copyWith(
            pvAiWins: config.humanColor == ChessColor.white
                ? stats.pvAiWins + 1
                : stats.pvAiWins,
            pvAiLosses: config.humanColor == ChessColor.black
                ? stats.pvAiLosses + 1
                : stats.pvAiLosses,
          ),
        _GameResult.blackWin => stats.copyWith(
            pvAiWins: config.humanColor == ChessColor.black
                ? stats.pvAiWins + 1
                : stats.pvAiWins,
            pvAiLosses: config.humanColor == ChessColor.white
                ? stats.pvAiLosses + 1
                : stats.pvAiLosses,
          ),
        _ => stats.copyWith(pvAiDraws: stats.pvAiDraws + 1),
      };
    }

    await _repository.saveStatistics(updated);
  }

  _GameResult _resolveOutcome() {
    if (statusMessage?.contains('You win on time') ?? false) {
      return config.humanColor == ChessColor.white
          ? _GameResult.whiteWin
          : _GameResult.blackWin;
    }
    if (statusMessage?.contains('You lose on time') ?? false) {
      return config.humanColor == ChessColor.white
          ? _GameResult.blackWin
          : _GameResult.whiteWin;
    }
    if (statusMessage?.contains('Black wins on time') ?? false) {
      return _GameResult.blackWin;
    }
    if (statusMessage?.contains('White wins on time') ?? false) {
      return _GameResult.whiteWin;
    }
    if (status.isDraw) return _GameResult.draw;
    if (status.outcome == GameOutcome.checkmate) {
      return position.sideToMove == ChessColor.white
          ? _GameResult.blackWin
          : _GameResult.whiteWin;
    }
    return _GameResult.draw;
  }

  void copyPgn() {
    final white = config.isVsAi && config.humanColor == ChessColor.white
        ? 'You'
        : 'White';
    final black = config.isVsAi && config.humanColor == ChessColor.black
        ? 'You'
        : config.isVsAi
            ? 'Computer'
            : 'Black';
    Clipboard.setData(
      ClipboardData(text: game.exportPgn(white: white, black: black)),
    );
  }

  void copyFen() {
    Clipboard.setData(ClipboardData(text: game.fen));
  }

  void _clearSelection() {
    selectedSquare = null;
    legalTargets = [];
  }

  void _updateStatusMessage() {
    final message = _buildStatusMessage();
    if (message == null) return;

    statusMessage = message;
    game.clock.stop();
    _persistDebounce?.cancel();
    unawaited(_onGameFinished());
  }

  String? _buildStatusMessage() {
    final st = game.status;
    return switch (st.outcome) {
      GameOutcome.checkmate => _checkmateMessage(),
      GameOutcome.stalemate => config.isVsAi ? 'Draw by stalemate.' : 'Draw by stalemate',
      GameOutcome.drawFiftyMove =>
        config.isVsAi ? 'Draw by fifty-move rule.' : 'Draw by fifty-move rule',
      GameOutcome.drawRepetition =>
        config.isVsAi ? 'Draw by threefold repetition.' : 'Draw by threefold repetition',
      GameOutcome.drawInsufficientMaterial =>
        config.isVsAi ? 'Draw by insufficient material.' : 'Draw by insufficient material',
      GameOutcome.check => null,
      GameOutcome.ongoing => null,
    };
  }

  String _checkmateMessage() {
    final winner = position.sideToMove == ChessColor.white
        ? ChessColor.black
        : ChessColor.white;
    if (config.isVsAi) {
      return winner == config.humanColor
          ? 'You win by checkmate!'
          : 'You lose by checkmate.';
    }
    return '${winner == ChessColor.white ? 'White' : 'Black'} wins by checkmate';
  }

  String _timeoutMessage(ChessColor loser) {
    final winner = loser.opposite;
    if (config.isVsAi) {
      return winner == config.humanColor
          ? 'You win on time!'
          : 'You lose on time.';
    }
    return loser == ChessColor.white
        ? 'Black wins on time'
        : 'White wins on time';
  }

  String get gameOverTitle {
    if (!config.isVsAi || statusMessage == null) return 'Game over';
    final message = statusMessage!;
    if (message.startsWith('You win')) return 'Victory';
    if (message.startsWith('You lose')) return 'Defeat';
    return 'Draw';
  }

  @override
  bool isSquareHighlighted(Square square) {
    if (lastMove != null &&
        (lastMove!.from == square || lastMove!.to == square)) {
      return true;
    }
    if (selectedSquare == square) return true;
    return legalTargets.contains(square);
  }

  @override
  bool isSquareInCheck(Square square) {
    final piece = position.pieceAt(square);
    if (piece?.type != PieceType.king) return false;
    return AttackDetector.isInCheck(position, piece!.color);
  }
}

enum _GameResult { whiteWin, blackWin, draw }
