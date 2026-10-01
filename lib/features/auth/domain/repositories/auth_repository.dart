import 'package:chess/core/errors/result.dart';
import 'package:chess/features/auth/domain/entities/user_entity.dart';

/// Credentials for email/password authentication.
class AuthCredentials {
  const AuthCredentials({required this.email, required this.password});

  final String email;
  final String password;
}

/// Registration payload including display name.
class RegisterCredentials extends AuthCredentials {
  const RegisterCredentials({
    required super.email,
    required super.password,
    required this.displayName,
  });

  final String displayName;
}

/// Repository contract for authentication and user profile reads.
abstract class AuthRepository {
  bool get isAvailable;

  Stream<UserEntity?> get authStateChanges;

  UserEntity? get currentUser;

  Future<Result<UserEntity>> signInWithEmail(AuthCredentials credentials);

  Future<Result<UserEntity>> registerWithEmail(RegisterCredentials credentials);

  Future<Result<UserEntity>> signInWithGoogle();

  Future<Result<UserEntity>> signInAnonymously();

  Future<Result<void>> signOut();

  Future<Result<void>> sendPasswordResetEmail(String email);

  Future<Result<void>> deleteAccount();

  Future<Result<UserEntity>> getCurrentUserProfile();

  Future<Result<UserEntity>> restoreSession();
}
