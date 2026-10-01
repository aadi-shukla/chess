/// Current cloud sync status for UI.
enum SyncStatus {
  idle,
  syncing,
  success,
  offline,
  error,
}

/// Snapshot of the last sync operation.
class SyncState {
  const SyncState({
    this.status = SyncStatus.idle,
    this.lastSyncedAt,
    this.pendingOperations = 0,
    this.errorMessage,
  });

  final SyncStatus status;
  final DateTime? lastSyncedAt;
  final int pendingOperations;
  final String? errorMessage;

  bool get isSyncing => status == SyncStatus.syncing;

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncedAt,
    int? pendingOperations,
    String? errorMessage,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      pendingOperations: pendingOperations ?? this.pendingOperations,
      errorMessage: errorMessage,
    );
  }
}
