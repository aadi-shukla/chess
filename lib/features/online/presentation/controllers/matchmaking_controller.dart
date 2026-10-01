import 'dart:async';

import 'package:chess/app/routes/app_routes.dart';
import 'package:chess/core/utils/app_logger.dart';
import 'package:chess/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:chess/features/online/domain/entities/matchmaking.dart';
import 'package:chess/features/online/domain/repositories/online_game_repository.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Matchmaking: quick queue, private create/join, cancel, and reconnect.
class MatchmakingController extends GetxController {
  MatchmakingController(this._repository);

  final OnlineGameRepository _repository;

  String mode = 'casual';
  String timeControl = '10+0';
  MatchSearchType matchType = MatchSearchType.rated;
  bool isSearching = false;
  String? statusMessage;
  String? queueId;
  int ratingBand = 150;
  int waitSeconds = 0;
  MatchInvite? activeInvite;
  String inviteCodeInput = '';

  StreamSubscription<String?>? _activeGameSubscription;
  StreamSubscription<MatchInvite?>? _inviteSubscription;
  Timer? _pollTimer;
  Timer? _waitTimer;

  static const timeControls = [
    '3+0',
    '3+2',
    '5+0',
    '5+3',
    '10+0',
    '10+5',
    '15+10',
    '30+0',
  ];
  static final _inviteCodePattern = RegExp(r'^[A-Z0-9]{6}$');
  static const pollInterval = Duration(seconds: 4);

  @override
  void onClose() {
    unawaited(_activeGameSubscription?.cancel());
    unawaited(_inviteSubscription?.cancel());
    _pollTimer?.cancel();
    _waitTimer?.cancel();
    if (isSearching) {
      unawaited(_repository.leaveMatchmakingQueue());
    }
    super.onClose();
  }

  void setMode(String value) {
    mode = value;
    update();
  }

  void setTimeControl(String value) {
    timeControl = value;
    update();
  }

  void setMatchType(MatchSearchType value) {
    matchType = value;
    update();
  }

  void setInviteCode(String value) {
    inviteCodeInput = value.toUpperCase();
  }

  Future<void> startSearch() async {
    if (isSearching) return;
    if (!timeControls.contains(timeControl)) return;

    final uid = Get.find<AuthSessionController>().user.value?.uid;
    if (uid == null) return;

    isSearching = true;
    statusMessage = 'Searching for opponent…';
    waitSeconds = 0;
    ratingBand = 150;
    activeInvite = null;
    update();

    _listenForActiveGame(uid);

    try {
      final result = await _repository.joinMatchmakingQueue(
        mode: mode,
        timeControl: timeControl,
        matchType: matchType,
      );

      if (await _handleMatchResult(result)) return;

      queueId = result['queueId'] as String?;
      ratingBand = (result['ratingBand'] as num?)?.toInt() ?? 150;
      statusMessage = _waitingMessage();
      _startPolling();
      _startWaitTimer();
      update();
    } on Exception catch (error) {
      AppLogger.instance.e('Matchmaking failed', error: error);
      await _resetSearch();
      statusMessage = 'Matchmaking failed — try again';
      update();
    }
  }

  Future<void> cancelSearch() async {
    _pollTimer?.cancel();
    _waitTimer?.cancel();
    await _inviteSubscription?.cancel();
    _inviteSubscription = null;
    await _repository.leaveMatchmakingQueue();
    await _resetSearch();
    update();
  }

  Future<void> createRoom() async {
    if (isSearching) return;

    isSearching = true;
    statusMessage = 'Creating room…';
    activeInvite = null;
    update();

    try {
      final invite = await _repository.createPrivateMatch(
        mode: mode,
        timeControl: timeControl,
      );
      activeInvite = invite;
      isSearching = true;
      statusMessage = 'Share code with your opponent';
      _listenForInvite(invite.inviteCode);
      _listenForActiveGame(
        Get.find<AuthSessionController>().user.value!.uid,
      );
      update();
    } on Exception catch (error) {
      AppLogger.instance.e('Create room failed', error: error);
      isSearching = false;
      statusMessage = 'Could not create room — try again';
      update();
    }
  }

  Future<void> joinRoom() async {
    final code = inviteCodeInput.trim().toUpperCase();
    if (!_inviteCodePattern.hasMatch(code)) {
      statusMessage = 'Enter a valid 6-character invite code';
      update();
      return;
    }

    isSearching = true;
    statusMessage = 'Joining room…';
    update();

    try {
      final gameId = await _repository.joinPrivateMatch(code);
      await _navigateToGame(gameId);
    } on Exception catch (error) {
      AppLogger.instance.e('Join room failed', error: error);
      isSearching = false;
      statusMessage = 'Invalid or expired code';
      update();
    }
  }

  Future<void> copyInviteCode() async {
    final code = activeInvite?.inviteCode;
    if (code == null) return;
    await Clipboard.setData(ClipboardData(text: code));
    statusMessage = 'Code copied to clipboard';
    update();
  }

  void _listenForActiveGame(String uid) {
    _activeGameSubscription?.cancel();
    _activeGameSubscription = _repository.watchActiveGameId(uid).listen(
      (gameId) {
        if (gameId != null && isSearching) {
          unawaited(_navigateToGame(gameId));
        }
      },
    );
  }

  void _listenForInvite(String code) {
    _inviteSubscription?.cancel();
    _inviteSubscription = _repository.watchMatchInvite(code).listen(
      (invite) {
        if (invite == null) return;
        activeInvite = invite;
        if (invite.isStarted && invite.gameId != null) {
          unawaited(_navigateToGame(invite.gameId!));
        }
        update();
      },
    );
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(pollInterval, (_) {
      unawaited(_pollQueue());
    });
  }

  void _startWaitTimer() {
    _waitTimer?.cancel();
    _waitTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      waitSeconds++;
      statusMessage = _waitingMessage();
      update();
    });
  }

  Future<void> _pollQueue() async {
    final id = queueId;
    if (id == null || !isSearching) return;

    try {
      final result = await _repository.pollMatchmakingQueue(id);
      ratingBand = (result['ratingBand'] as num?)?.toInt() ?? ratingBand;
      if (await _handleMatchResult(result)) return;
      statusMessage = _waitingMessage();
      update();
    } on Exception catch (error) {
      AppLogger.instance.w('Queue poll failed', error: error);
      final status = await _repository.getQueueStatus();
      if (status.isMatched && status.gameId != null) {
        await _navigateToGame(status.gameId!);
      } else if (status.isIdle) {
        await _resetSearch();
        statusMessage = 'Search expired — try again';
        update();
      }
    }
  }

  Future<bool> _handleMatchResult(Map<String, dynamic> result) async {
    if (result['status'] == 'matched') {
      final gameId = result['gameId'] as String?;
      if (gameId != null) {
        await _navigateToGame(gameId);
        return true;
      }
    }
    return false;
  }

  String _waitingMessage() {
    final typeLabel =
        matchType == MatchSearchType.random ? 'random' : 'rated ±$ratingBand';
    return 'Waiting for opponent… ${waitSeconds}s ($typeLabel)';
  }

  Future<void> _navigateToGame(String gameId) async {
    _pollTimer?.cancel();
    _waitTimer?.cancel();
    await _activeGameSubscription?.cancel();
    await _inviteSubscription?.cancel();
    isSearching = false;
    queueId = null;
    await Get.offNamed<void>(
      AppRoutes.onlineGame,
      parameters: {'gameId': gameId},
    );
  }

  Future<void> _resetSearch() async {
    _pollTimer?.cancel();
    _waitTimer?.cancel();
    await _activeGameSubscription?.cancel();
    _activeGameSubscription = null;
    isSearching = false;
    queueId = null;
    activeInvite = null;
    waitSeconds = 0;
  }
}
