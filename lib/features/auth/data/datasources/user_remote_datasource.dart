import 'package:chess/core/firebase/firestore_paths.dart';
import 'package:chess/core/firebase/firestore_service.dart';
import 'package:chess/features/auth/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Remote data source for Firestore user profile documents.
class UserRemoteDataSource {
  UserRemoteDataSource(this._firestoreService);

  final FirestoreService _firestoreService;

  Future<UserModel?> getUserProfile(String uid) async {
    final snapshot = await _firestoreService
        .document(FirestorePaths.user(uid))
        .get();

    if (!snapshot.exists) return null;
    return UserModel.fromFirestore(snapshot);
  }

  Stream<UserModel?> watchUserProfile(String uid) {
    return _firestoreService.document(FirestorePaths.user(uid)).snapshots().map(
      (snapshot) {
        if (!snapshot.exists) return null;
        return UserModel.fromFirestore(snapshot);
      },
    );
  }

  /// Creates a user profile when the Cloud Function trigger has not run yet.
  Future<void> ensureUserProfile({
    required String uid,
    required String email,
    required String displayName,
    String? photoUrl,
    bool isAnonymous = false,
  }) async {
    final ref = _firestoreService.document(FirestorePaths.user(uid));
    final existing = await ref.get();
    if (existing.exists) return;

    final resolvedName = isAnonymous ? 'Guest Player' : displayName;

    await ref.set({
      'email': email,
      'displayName': resolvedName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'rating': 1200,
      'stats': {
        'played': 0,
        'wins': 0,
        'losses': 0,
        'draws': 0,
      },
      'isAnonymous': isAnonymous,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
