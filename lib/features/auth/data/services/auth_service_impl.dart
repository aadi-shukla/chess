import 'package:chess/features/auth/data/services/auth_service.dart';
import 'package:chess/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// [AuthService] implementation using [firebase.FirebaseAuth].
class AuthServiceImpl implements AuthService {
  AuthServiceImpl({
    firebase.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? firebase.FirebaseAuth.instance,
        _googleSignInOverride = googleSignIn;

  final firebase.FirebaseAuth _firebaseAuth;
  final GoogleSignIn? _googleSignInOverride;
  GoogleSignIn? _googleSignInInstance;

  /// Mobile/desktop only — web uses [signInWithPopup] and must not construct
  /// [GoogleSignIn] without a client ID.
  GoogleSignIn get _mobileGoogleSignIn {
    if (kIsWeb) {
      throw StateError('GoogleSignIn is not used on web.');
    }
    return _googleSignInOverride ?? (_googleSignInInstance ??= GoogleSignIn());
  }

  @override
  Stream<firebase.User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  firebase.User? get currentFirebaseUser => _firebaseAuth.currentUser;

  @override
  Future<firebase.UserCredential> signInWithEmailAndPassword(
    AuthCredentials credentials,
  ) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: credentials.email.trim(),
      password: credentials.password,
    );
  }

  @override
  Future<firebase.UserCredential> registerWithEmailAndPassword(
    RegisterCredentials credentials,
  ) async {
    final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: credentials.email.trim(),
      password: credentials.password,
    );

    await userCredential.user?.updateDisplayName(credentials.displayName.trim());
    await userCredential.user?.reload();

    return userCredential;
  }

  @override
  Future<firebase.UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = firebase.GoogleAuthProvider();
      return _firebaseAuth.signInWithPopup(provider);
    }

    final googleUser = await _mobileGoogleSignIn.signIn();
    if (googleUser == null) {
      throw firebase.FirebaseAuthException(
        code: 'popup-closed-by-user',
        message: 'Google sign-in was cancelled.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = firebase.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return _firebaseAuth.signInWithCredential(credential);
  }

  @override
  Future<firebase.UserCredential> signInAnonymously() {
    return _firebaseAuth.signInAnonymously();
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    if (!kIsWeb) {
      await _mobileGoogleSignIn.signOut();
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  @override
  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw firebase.FirebaseAuthException(
        code: 'user-not-found',
        message: 'No signed-in user.',
      );
    }
    await user.delete();
    if (!kIsWeb) {
      await _mobileGoogleSignIn.signOut();
    }
  }
}
