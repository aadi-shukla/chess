import 'package:chess/core/firebase/firestore_paths.dart';
import 'package:chess/core/firebase/firestore_service.dart';
import 'package:chess/features/game/domain/entities/cloud_game_settings.dart';
import 'package:chess/features/game/domain/entities/game_history_entry.dart';
import 'package:chess/features/game/domain/entities/saved_game.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore read/write for per-user cloud game data.
class GameRemoteDataSource {
  GameRemoteDataSource(this._firestore);

  final FirestoreService _firestore;

  DocumentReference<Map<String, dynamic>> _settingsDoc(String uid) {
    return _firestore.document(FirestorePaths.userSettings(uid));
  }

  DocumentReference<Map<String, dynamic>> _gameDoc(
    String uid,
    String gameId,
  ) {
    return _firestore.document(FirestorePaths.userGame(uid, gameId));
  }

  CollectionReference<Map<String, dynamic>> _historyCollection(String uid) {
    return _firestore.document(FirestorePaths.user(uid)).collection('history');
  }

  Future<void> upsertSavedGame({
    required String uid,
    required SavedGame game,
  }) async {
    await _gameDoc(uid, game.id).set(
      {
        ...game.toCloudJson(ownerUid: uid),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> deleteSavedGame({
    required String uid,
    required String gameId,
  }) async {
    await _gameDoc(uid, gameId).set(
      {
        'deleted': true,
        'status': 'deleted',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<SavedGame?> fetchActiveSavedGame(String uid) async {
    // Single equality filter — no composite Firestore index required.
    // Deleted games use status "deleted", so in_progress is sufficient.
    final snapshot = await _firestore
        .document(FirestorePaths.user(uid))
        .collection('games')
        .where('status', isEqualTo: 'in_progress')
        .get();

    if (snapshot.docs.isEmpty) return null;

    final games = snapshot.docs
        .map((doc) => SavedGame.fromCloudJson(doc.data()))
        .where((game) => !game.deleted)
        .toList()
      ..sort((a, b) => b.updatedAtMillis.compareTo(a.updatedAtMillis));

    return games.isEmpty ? null : games.first;
  }

  Future<void> upsertSettings({
    required String uid,
    required CloudGameSettings settings,
  }) async {
    await _settingsDoc(uid).set(
      {
        ...settings.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<CloudGameSettings?> fetchSettings(String uid) async {
    final doc = await _settingsDoc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return CloudGameSettings.fromJson(doc.data()!);
  }

  Future<void> upsertHistoryEntry({
    required String uid,
    required GameHistoryEntry entry,
  }) async {
    await _historyCollection(uid).doc(entry.id).set({
      ...entry.toJson(),
      'ownerUid': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<GameHistoryEntry>> fetchHistory(String uid, {int limit = 50}) async {
    final snapshot = await _historyCollection(uid)
        .orderBy('completedAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => GameHistoryEntry.fromJson(doc.data()))
        .toList();
  }
}
