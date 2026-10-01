/// How opponents are selected in the public queue.
enum MatchSearchType {
  rated,
  random;

  String get value => name;

  static MatchSearchType fromString(String? value) {
    return value == 'random' ? MatchSearchType.random : MatchSearchType.rated;
  }
}

/// Current matchmaking queue state for the signed-in user.
class QueueStatus {
  const QueueStatus({
    required this.status,
    this.queueId,
    this.gameId,
    this.mode,
    this.matchType,
    this.timeControl,
    this.ratingBand,
    this.waitSeconds = 0,
    this.expiresAt,
  });

  const QueueStatus.idle() : this(status: 'idle');

  factory QueueStatus.fromMap(Map<String, dynamic> map) {
    return QueueStatus(
      status: map['status'] as String? ?? 'idle',
      queueId: map['queueId'] as String?,
      gameId: map['gameId'] as String?,
      mode: map['mode'] as String?,
      matchType: map['matchType'] as String?,
      timeControl: map['timeControl'] as String?,
      ratingBand: (map['ratingBand'] as num?)?.toInt(),
      waitSeconds: (map['waitSeconds'] as num?)?.toInt() ?? 0,
      expiresAt: map['expiresAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['expiresAt'] as int)
          : null,
    );
  }

  final String status;
  final String? queueId;
  final String? gameId;
  final String? mode;
  final String? matchType;
  final String? timeControl;
  final int? ratingBand;
  final int waitSeconds;
  final DateTime? expiresAt;

  bool get isIdle => status == 'idle';
  bool get isWaiting => status == 'waiting' || status == 'queued';
  bool get isMatched => status == 'matched';
}

/// Private match invite created by the host.
class MatchInvite {
  const MatchInvite({
    required this.inviteCode,
    required this.expiresAt,
    required this.mode,
    required this.timeControl,
    this.gameId,
    this.status = 'open',
  });

  factory MatchInvite.fromMap(Map<String, dynamic> map) {
    return MatchInvite(
      inviteCode: map['inviteCode'] as String? ?? '',
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        (map['expiresAt'] as num?)?.toInt() ?? 0,
      ),
      mode: map['mode'] as String? ?? 'casual',
      timeControl: map['timeControl'] as String? ?? '10+0',
      gameId: map['gameId'] as String?,
      status: map['status'] as String? ?? 'open',
    );
  }

  final String inviteCode;
  final DateTime expiresAt;
  final String mode;
  final String timeControl;
  final String? gameId;
  final String status;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isStarted => status == 'started' || gameId != null;
}
