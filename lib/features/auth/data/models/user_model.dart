import 'package:chess/features/auth/domain/entities/user_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore DTO for `users/{uid}` documents.
class UserModel {
  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.rating = 1200,
    this.activeGameId,
  });

  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return UserModel(
      uid: snapshot.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? 'Player',
      photoUrl: data['photoUrl'] as String?,
      rating: (data['rating'] as num?)?.toInt() ?? 1200,
      activeGameId: data['activeGameId'] as String?,
    );
  }

  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final int rating;
  final String? activeGameId;

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'rating': rating,
    };
  }
}

/// Maps between [UserModel] and [UserEntity].
abstract final class UserMapper {
  static UserEntity toEntity(
    UserModel model, {
    bool isAnonymous = false,
    bool emailVerified = false,
  }) {
    return UserEntity(
      uid: model.uid,
      email: model.email,
      displayName: model.displayName,
      photoUrl: model.photoUrl,
      rating: model.rating,
      isAnonymous: isAnonymous,
      emailVerified: emailVerified,
      activeGameId: model.activeGameId,
    );
  }

  static UserEntity fromFirebaseUser({
    required String uid,
    required String? email,
    required String? displayName,
    required String? photoUrl,
    required bool isAnonymous,
    required bool emailVerified,
    int rating = 1200,
  }) {
    return UserEntity(
      uid: uid,
      email: email ?? '',
      displayName: displayName ?? 'Player',
      photoUrl: photoUrl,
      rating: rating,
      isAnonymous: isAnonymous,
      emailVerified: emailVerified,
    );
  }
}
