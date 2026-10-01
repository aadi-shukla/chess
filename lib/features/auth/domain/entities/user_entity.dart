/// Domain user entity — independent of Firebase types.
class UserEntity {
  const UserEntity({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.rating = 1200,
    this.isAnonymous = false,
    this.emailVerified = false,
    this.activeGameId,
  });

  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final int rating;
  final bool isAnonymous;
  final bool emailVerified;
  final String? activeGameId;

  UserEntity copyWith({
    String? email,
    String? displayName,
    String? photoUrl,
    int? rating,
    bool? isAnonymous,
    bool? emailVerified,
    String? activeGameId,
  }) {
    return UserEntity(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      rating: rating ?? this.rating,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      emailVerified: emailVerified ?? this.emailVerified,
      activeGameId: activeGameId ?? this.activeGameId,
    );
  }
}
