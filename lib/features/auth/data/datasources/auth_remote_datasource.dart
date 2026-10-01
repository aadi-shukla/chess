import 'package:chess/features/auth/data/services/auth_service.dart';
import 'package:chess/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;

/// Remote data source for Firebase Auth operations.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._authService);

  final AuthService _authService;

  Stream<firebase.User?> get authStateChanges => _authService.authStateChanges;

  firebase.User? get currentFirebaseUser => _authService.currentFirebaseUser;

  Future<firebase.UserCredential> signInWithEmail(AuthCredentials credentials) {
    return _authService.signInWithEmailAndPassword(credentials);
  }

  Future<firebase.UserCredential> registerWithEmail(
    RegisterCredentials credentials,
  ) {
    return _authService.registerWithEmailAndPassword(credentials);
  }

  Future<firebase.UserCredential> signInWithGoogle() {
    return _authService.signInWithGoogle();
  }

  Future<firebase.UserCredential> signInAnonymously() {
    return _authService.signInAnonymously();
  }

  Future<void> signOut() => _authService.signOut();

  Future<void> sendPasswordResetEmail(String email) {
    return _authService.sendPasswordResetEmail(email);
  }

  Future<void> deleteAccount() => _authService.deleteAccount();
}
