import 'package:chess/chess_engine/chess_engine.dart';

/// Draw offer state on an online game document.
class DrawOffer {
  const DrawOffer({required this.offeredBy, required this.status});

  final String offeredBy;
  final String status;

  bool get isPending => status == 'pending';
}

/// Remote move entry stored in Firestore `moveHistory`.
class OnlineMoveRecord {
  const OnlineMoveRecord({
    required this.san,
    required this.from,
    required this.to,
    this.promotion,
    this.byUid,
  });

  final String san;
  final String from;
  final String to;
  final String? promotion;
  final String? byUid;
}

/// Live online game snapshot from `games/{gameId}`.
class OnlineGame {
  const OnlineGame({
    required this.id,
    required this.whiteUid,
    required this.blackUid,
    required this.status,
    required this.fen,
    required this.turn,
    required this.version,
    required this.timeControl,
    required this.mode,
    required this.moveHistory,
    required this.whiteMillis,
    required this.blackMillis,
    required this.incrementMillis,
    this.result,
    this.endReason,
    this.drawOffer,
    this.lastMoveAt,
  });

  final String id;
  final String whiteUid;
  final String blackUid;
  final String status;
  final String fen;
  final String turn;
  final int version;
  final String timeControl;
  final String mode;
  final List<OnlineMoveRecord> moveHistory;
  final int whiteMillis;
  final int blackMillis;
  final int incrementMillis;
  final String? result;
  final String? endReason;
  final DrawOffer? drawOffer;
  final DateTime? lastMoveAt;

  bool get isActive => status == 'active';
  bool get isFinished => status == 'finished';
  bool get isRated => mode == 'rated';

  ChessColor get turnColor =>
      turn == 'white' ? ChessColor.white : ChessColor.black;

  bool isWhite(String uid) => whiteUid == uid;
  bool isBlack(String uid) => blackUid == uid;

  ChessColor colorFor(String uid) {
    if (isWhite(uid)) return ChessColor.white;
    if (isBlack(uid)) return ChessColor.black;
    throw StateError('User is not a participant.');
  }

  bool isMyTurn(String uid) {
    if (turn == 'white') return isWhite(uid);
    return isBlack(uid);
  }
}
