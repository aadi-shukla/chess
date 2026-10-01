import 'package:chess/features/online/domain/entities/online_game.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore DTO for `games/{gameId}`.
class OnlineGameModel {
  const OnlineGameModel({
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

  factory OnlineGameModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    final history = (data['moveHistory'] as List<dynamic>? ?? [])
        .map((entry) {
          final map = entry as Map<String, dynamic>;
          return OnlineMoveRecord(
            san: map['san'] as String? ?? '',
            from: map['from'] as String? ?? '',
            to: map['to'] as String? ?? '',
            promotion: map['promotion'] as String?,
            byUid: map['byUid'] as String?,
          );
        })
        .toList();

    DrawOffer? drawOffer;
    final drawRaw = data['drawOffer'] as Map<String, dynamic>?;
    if (drawRaw != null) {
      drawOffer = DrawOffer(
        offeredBy: drawRaw['offeredBy'] as String? ?? '',
        status: drawRaw['status'] as String? ?? 'pending',
      );
    }

    final lastMoveAt = data['lastMoveAt'];
    DateTime? parsedLastMoveAt;
    if (lastMoveAt is Timestamp) {
      parsedLastMoveAt = lastMoveAt.toDate();
    }

    return OnlineGameModel(
      id: snapshot.id,
      whiteUid: data['whiteUid'] as String? ?? '',
      blackUid: data['blackUid'] as String? ?? '',
      status: data['status'] as String? ?? 'active',
      fen: data['fen'] as String? ?? '',
      turn: data['turn'] as String? ?? 'white',
      version: (data['version'] as num?)?.toInt() ?? 1,
      timeControl: data['timeControl'] as String? ?? '10+0',
      mode: data['mode'] as String? ?? 'casual',
      moveHistory: history,
      whiteMillis: (data['whiteMillis'] as num?)?.toInt() ?? 600000,
      blackMillis: (data['blackMillis'] as num?)?.toInt() ?? 600000,
      incrementMillis: (data['incrementMillis'] as num?)?.toInt() ?? 0,
      result: data['result'] as String?,
      endReason: data['endReason'] as String?,
      drawOffer: drawOffer,
      lastMoveAt: parsedLastMoveAt,
    );
  }

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
}

abstract final class OnlineGameMapper {
  static OnlineGame toEntity(OnlineGameModel model) {
    return OnlineGame(
      id: model.id,
      whiteUid: model.whiteUid,
      blackUid: model.blackUid,
      status: model.status,
      fen: model.fen,
      turn: model.turn,
      version: model.version,
      timeControl: model.timeControl,
      mode: model.mode,
      moveHistory: model.moveHistory,
      whiteMillis: model.whiteMillis,
      blackMillis: model.blackMillis,
      incrementMillis: model.incrementMillis,
      result: model.result,
      endReason: model.endReason,
      drawOffer: model.drawOffer,
      lastMoveAt: model.lastMoveAt,
    );
  }
}
