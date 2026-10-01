import 'dart:async';

import 'package:chess/chess_engine/chess_engine.dart';
import 'package:chess/core/network/connectivity_service.dart';
import 'package:chess/core/utils/app_logger.dart';
import 'package:chess/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:chess/features/game/domain/entities/board_theme.dart';
import 'package:chess/features/game/domain/repositories/game_repository.dart';
import 'package:chess/features/game/presentation/board/chess_board_host.dart';
import 'package:chess/features/online/data/datasources/online_game_remote_datasource.dart';
import 'package:chess/features/online/domain/entities/online_game.dart';
import 'package:chess/features/online/domain/repositories/online_game_repository.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Realtime online chess session backed by Firestore + Cloud Functions.
class OnlineGameController extends GetxController
    implements ChessBoardHost, PromotionHost {
  OnlineGameController({
    required OnlineGameRepository repository,
    required GameRepository gameRepository,
    required ConnectivityService connectivity,
  })  : _repository = repository,
        _gameRepository = gameRepository,
        _connectivity = connectivity;

  static const boardId = 'board';
  static const clockId = 'clock';
  static const chromeId = 'chrome';

  final OnlineGameRepository _repository;
  final GameRepository _gameRepository;
  final ConnectivityService _connectivity;

  late String gameId;
  late String myUid;
  late ChessGame game;
  BoardTheme _boardTheme = BoardTheme.classic;

  OnlineGame? remoteGame;
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

  String? statusMessage;
  bool isSubmittingMove = false;
  bool isOnline = true;
  int _serverVersion = 0;
  final whiteMillisRx = 0.obs;
  final blackMillisRx = 0.obs;

  StreamSubscription<OnlineGame?>? _gameSubscription;
  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _clockTimer;

  @override
  Position get position => game.position;

  @override
  BoardTheme get boardTheme => _boardTheme;

  int get whiteMillis => whiteMillisRx.value;
  int get blackMillis => blackMillisRx.value;

  List<String> get moveHistory =>
      remoteGame?.moveHistory.map((m) => m.san).toList() ?? game.sans;

  bool get isGameOver => remoteGame?.isFinished ?? false;
  bool get isMyTurn =>
      remoteGame != null && remoteGame!.isMyTurn(myUid) && !isGameOver;

  ChessColor get myColor => remoteGame!.colorFor(myUid);

  DrawOffer? get drawOffer => remoteGame?.drawOffer;

  bool get hasIncomingDrawOffer {
    final offer = drawOffer;
    return offer != null &&
        offer.isPending &&
        offer.offeredBy != myUid;
  }

  @override
  void onInit() {
    super.onInit();
    gameId = Get.parameters['gameId'] ?? Get.arguments as String? ?? '';
    myUid = Get.find<AuthSessionController>().user.value?.uid ?? '';
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    if (gameId.isEmpty || myUid.isEmpty) {
      statusMessage = 'Invalid game session';
      _refreshChrome();
      return;
    }

    _boardTheme = await _gameRepository.loadBoardTheme();
    game = ChessGame(
      initialClock: ChessClock(),
    );

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((online) {
      isOnline = online;
      _refreshChrome();
    });
    isOnline = _connectivity.isOnline;

    _gameSubscription = _repository.watchGame(gameId).listen(
      _onGameSnapshot,
      onError: (Object error) {
        AppLogger.instance.e('Online game stream error', error: error);
        statusMessage = 'Connection error — retrying…';
        _refreshChrome();
      },
    );

    _startClockTimer();
  }

  void _onGameSnapshot(OnlineGame? snapshot) {
    if (snapshot == null) {
      statusMessage = 'Game not found';
      _refreshChrome();
      return;
    }

    remoteGame = snapshot;
    if (!snapshot.isWhite(myUid) && !snapshot.isBlack(myUid)) {
      statusMessage = 'You are not a participant in this game';
      _refreshChrome();
      return;
    }

    boardFlipped = snapshot.isBlack(myUid);

    if (snapshot.version != _serverVersion || isSubmittingMove == false) {
      _applyRemoteState(snapshot);
    }

    _updateStatusMessage(snapshot);
    _refreshAll();
  }

  void _refreshAll() => update([boardId, clockId, chromeId]);

  void _refreshBoard() => update([boardId, clockId]);

  void _refreshChrome() => update([chromeId]);

  void _applyRemoteState(OnlineGame snapshot) {
    _serverVersion = snapshot.version;
    whiteMillisRx.value = snapshot.whiteMillis;
    blackMillisRx.value = snapshot.blackMillis;

    game = ChessGame(
      initialPosition: FenParser.fromFen(snapshot.fen),
      initialClock: ChessClock(
        whiteMillis: snapshot.whiteMillis,
        blackMillis: snapshot.blackMillis,
        incrementMillis: snapshot.incrementMillis,
      ),
    );

    if (snapshot.moveHistory.isNotEmpty) {
      final last = snapshot.moveHistory.last;
      final from = Square.fromAlgebraic(last.from);
      final to = Square.fromAlgebraic(last.to);
      if (from != null && to != null) {
        lastMove = ChessMove(
          from: from,
          to: to,
          promotion: _parsePromotion(last.promotion),
        );
      }
    } else {
      lastMove = null;
    }

    if (!isMyTurn) {
      _clearSelection();
    }
  }

  PieceType _parsePromotion(String? promotion) {
    return switch (promotion) {
      'q' => PieceType.queen,
      'r' => PieceType.rook,
      'b' => PieceType.bishop,
      'n' => PieceType.knight,
      _ => PieceType.queen,
    };
  }

  void _updateStatusMessage(OnlineGame snapshot) {
    if (!snapshot.isFinished) {
      if (!isOnline) {
        statusMessage = 'Offline — moves resume when reconnected';
      } else if (hasIncomingDrawOffer) {
        statusMessage = 'Opponent offered a draw';
      } else {
        statusMessage = isMyTurn ? 'Your turn' : "Opponent's turn";
      }
      return;
    }

    statusMessage = switch (snapshot.result) {
      'white_wins' =>
        snapshot.isWhite(myUid) ? 'You won' : 'You lost',
      'black_wins' =>
        snapshot.isBlack(myUid) ? 'You won' : 'You lost',
      'draw' => 'Draw',
      _ => 'Game over',
    };
  }

  void _startClockTimer() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final remote = remoteGame;
      if (remote == null || remote.isFinished) return;

      final elapsed = remote.lastMoveAt == null
          ? 0
          : DateTime.now().difference(remote.lastMoveAt!).inMilliseconds;

      if (remote.turn == 'white') {
        whiteMillisRx.value =
            (remote.whiteMillis - elapsed).clamp(0, 999999999);
        blackMillisRx.value = remote.blackMillis;
        if (whiteMillisRx.value == 0 && isMyTurn && remote.isWhite(myUid)) {
          unawaited(_onLocalTimeout('white'));
        } else if (whiteMillisRx.value == 0 &&
            !remote.isWhite(myUid) &&
            isOnline) {
          unawaited(_claimOpponentTimeout('white'));
        }
      } else {
        blackMillisRx.value =
            (remote.blackMillis - elapsed).clamp(0, 999999999);
        whiteMillisRx.value = remote.whiteMillis;
        if (blackMillisRx.value == 0 && isMyTurn && remote.isBlack(myUid)) {
          unawaited(_onLocalTimeout('black'));
        } else if (blackMillisRx.value == 0 &&
            !remote.isBlack(myUid) &&
            isOnline) {
          unawaited(_claimOpponentTimeout('black'));
        }
      }
    });
  }

  Future<void> _onLocalTimeout(String side) async {
    if (isGameOver) return;
    statusMessage = 'Time expired';
    _refreshChrome();
  }

  Future<void> _claimOpponentTimeout(String side) async {
    if (isGameOver || !isOnline) return;
    try {
      await _repository.claimTimeout(gameId: gameId, timedOutSide: side);
    } on Exception catch (error) {
      AppLogger.instance.w('Timeout claim failed', error: error);
    }
  }

  @override
  void onSquareTap(Square square) {
    if (!isMyTurn || isSubmittingMove || isGameOver || !isOnline) return;

    final piece = position.pieceAt(square);
    final isOwnPiece = piece != null && piece.color == position.sideToMove;

    if (selectedSquare == square) {
      _clearSelection();
      _refreshBoard();
      return;
    }

    if (selectedSquare != null && legalTargets.contains(square)) {
      unawaited(_attemptMove(selectedSquare!, square));
      return;
    }

    if (isOwnPiece) {
      selectedSquare = square;
      legalTargets =
          game.legalMovesFrom(square).map((m) => m.to).toSet().toList();
      _refreshBoard();
      return;
    }

    _clearSelection();
    _refreshBoard();
  }

  Future<void> _attemptMove(Square from, Square to) async {
    final candidates =
        game.legalMovesFrom(from).where((m) => m.to == to).toList();
    if (candidates.isEmpty) return;

    if (candidates.length > 1) {
      pendingPromotionFrom = from;
      pendingPromotionTo = to;
      _refreshBoard();
      return;
    }

    await _submitMove(candidates.first);
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
    unawaited(_submitMove(move));
  }

  @override
  void cancelPromotion() {
    pendingPromotionFrom = null;
    pendingPromotionTo = null;
    _clearSelection();
    _refreshBoard();
  }

  Future<void> _submitMove(ChessMove move) async {
    if (remoteGame == null) return;

    final san = SanConverter.toSan(position, move);
    isSubmittingMove = true;
    _clearSelection();
    _refreshChrome();

    try {
      await _repository.submitMove(
        gameId: gameId,
        from: move.from.algebraic,
        to: move.to.algebraic,
        san: san,
        expectedVersion: _serverVersion,
        promotion: move.promotion != PieceType.queen || _isPromotion(move)
            ? _promotionChar(move.promotion)
            : null,
      );
      await HapticFeedback.lightImpact();
    } on VersionConflictException {
      statusMessage = 'Move conflict — syncing latest position';
      final latest = await _repository.getGame(gameId);
      if (latest != null) _applyRemoteState(latest);
    } on Exception catch (error) {
      AppLogger.instance.e('Submit move failed', error: error);
      statusMessage = 'Move failed — try again';
    } finally {
      isSubmittingMove = false;
      _refreshAll();
    }
  }

  String _promotionChar(PieceType type) => switch (type) {
        PieceType.queen => 'q',
        PieceType.rook => 'r',
        PieceType.bishop => 'b',
        PieceType.knight => 'n',
        _ => 'q',
      };

  bool _isPromotion(ChessMove move) {
    final piece = position.pieceAt(move.from);
    return piece?.type == PieceType.pawn &&
        (move.to.rank == 0 || move.to.rank == 7);
  }

  Future<void> resign() async {
    if (isGameOver) return;
    await _repository.resignGame(gameId);
  }

  Future<void> offerDraw() async {
    if (isGameOver || !isMyTurn) return;
    await _repository.offerDraw(gameId);
  }

  Future<void> acceptDraw() async {
    await _repository.respondToDraw(gameId: gameId, accept: true);
  }

  Future<void> declineDraw() async {
    await _repository.respondToDraw(gameId: gameId, accept: false);
  }

  void toggleBoardFlip() {
    boardFlipped = !boardFlipped;
    _refreshBoard();
  }

  @override
  bool isSquareHighlighted(Square square) => selectedSquare == square;

  @override
  bool isSquareInCheck(Square square) {
    final piece = position.pieceAt(square);
    if (piece?.type != PieceType.king) return false;
    return AttackDetector.isInCheck(position, piece!.color);
  }

  void _clearSelection() {
    selectedSquare = null;
    legalTargets = [];
  }

  @override
  void onClose() {
    unawaited(_gameSubscription?.cancel());
    unawaited(_connectivitySubscription?.cancel());
    _clockTimer?.cancel();
    super.onClose();
  }
}
