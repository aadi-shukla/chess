import 'package:chess/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;

/// Low-level wrapper around [firebase.FirebaseAuth].
abstract class AuthService {
  Stream<firebase.User?> get authStateChanges;

  firebase.User? get currentFirebaseUser;

  Future<firebase.UserCredential> signInWithEmailAndPassword(
    AuthCredentials credentials,
  );

  Future<firebase.UserCredential> registerWithEmailAndPassword(
    RegisterCredentials credentials,
  );

  Future<firebase.UserCredential> signInWithGoogle();

  Future<firebase.UserCredential> signInAnonymously();

  Future<void> signOut();

  Future<void> sendPasswordResetEmail(String email);

  Future<void> sendEmailVerification();

  Future<void> deleteAccount();
}
