/// Pending cloud operation stored while offline.
class SyncQueueEntry {
  const SyncQueueEntry({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAtMillis, this.retries = 0,
  });

  factory SyncQueueEntry.fromJson(Map<String, dynamic> json) {
    return SyncQueueEntry(
      id: json['id'] as String,
      type: SyncOperationType.values.byName(json['type'] as String),
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      retries: json['retries'] as int? ?? 0,
      createdAtMillis: json['createdAtMillis'] as int,
    );
  }

  final String id;
  final SyncOperationType type;
  final Map<String, dynamic> payload;
  final int retries;
  final int createdAtMillis;

  static const int maxRetries = 5;

  bool get canRetry => retries < maxRetries;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'payload': payload,
        'retries': retries,
        'createdAtMillis': createdAtMillis,
      };

  SyncQueueEntry withRetry() {
    return SyncQueueEntry(
      id: id,
      type: type,
      payload: payload,
      retries: retries + 1,
      createdAtMillis: createdAtMillis,
    );
  }
}

enum SyncOperationType {
  savedGame,
  clearGame,
  settings,
  history,
}
