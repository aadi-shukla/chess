import 'package:chess/core/errors/result.dart';
import 'package:chess/features/auth/domain/entities/user_entity.dart';
import 'package:chess/features/auth/domain/failures/auth_failure.dart';
import 'package:chess/features/auth/domain/repositories/auth_repository.dart';

/// Fallback repository when Firebase is not initialized.
class UnavailableAuthRepository implements AuthRepository {
  @override
  bool get isAvailable => false;

  @override
  Stream<UserEntity?> get authStateChanges => const Stream.empty();

  @override
  UserEntity? get currentUser => null;

  @override
  Future<Result<void>> deleteAccount() async =>
      const Error(FirebaseNotConfiguredFailure());

  @override
  Future<Result<UserEntity>> getCurrentUserProfile() async =>
      const Error(FirebaseNotConfiguredFailure());

  @override
  Future<Result<UserEntity>> registerWithEmail(
    RegisterCredentials credentials,
  ) async =>
      const Error(FirebaseNotConfiguredFailure());

  @override
  Future<Result<UserEntity>> restoreSession() async =>
      const Error(UserNotFoundFailure());

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async =>
      const Error(FirebaseNotConfiguredFailure());

  @override
  Future<Result<UserEntity>> signInAnonymously() async =>
      const Error(FirebaseNotConfiguredFailure());

  @override
  Future<Result<UserEntity>> signInWithEmail(AuthCredentials credentials) async =>
      const Error(FirebaseNotConfiguredFailure());

  @override
  Future<Result<UserEntity>> signInWithGoogle() async =>
      const Error(FirebaseNotConfiguredFailure());

  @override
  Future<Result<void>> signOut() async => const Success(null);
}
