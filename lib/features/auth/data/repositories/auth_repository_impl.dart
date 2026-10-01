import 'dart:async';

import 'package:chess/core/errors/result.dart';
import 'package:chess/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:chess/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:chess/features/auth/data/datasources/user_remote_datasource.dart';
import 'package:chess/features/auth/data/models/user_model.dart';
import 'package:chess/features/auth/domain/entities/user_entity.dart';
import 'package:chess/features/auth/domain/failures/auth_failure.dart';
import 'package:chess/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;

/// [AuthRepository] implementation — coordinates auth + user profile data.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource authRemoteDataSource,
    required UserRemoteDataSource userRemoteDataSource,
    required AuthLocalDataSource authLocalDataSource,
  })  : _authRemote = authRemoteDataSource,
        _userRemote = userRemoteDataSource,
        _authLocal = authLocalDataSource;

  final AuthRemoteDataSource _authRemote;
  final UserRemoteDataSource _userRemote;
  final AuthLocalDataSource _authLocal;

  final Set<String> _ensuredProfileUids = {};
  String? _cachedProfileUid;
  UserEntity? _cachedProfile;

  @override
  bool get isAvailable => true;

  @override
  Stream<UserEntity?> get authStateChanges {
    return _authRemote.authStateChanges.asyncMap(_mapFirebaseUser);
  }

  @override
  UserEntity? get currentUser {
    final firebaseUser = _authRemote.currentFirebaseUser;
    if (firebaseUser == null) return null;
    return UserMapper.fromFirebaseUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email,
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      isAnonymous: firebaseUser.isAnonymous,
      emailVerified: firebaseUser.emailVerified,
    );
  }

  @override
  Future<Result<UserEntity>> restoreSession() async {
    final cached = await _authLocal.readSession();
    final firebaseUser = _authRemote.currentFirebaseUser;

    if (firebaseUser != null) {
      try {
        final user = await _resolveUser(firebaseUser);
        await _authLocal.saveSession(user);
        return Success(user);
      } on Exception catch (error) {
        return Error(UnknownAuthFailure(error.toString()));
      }
    }

    if (cached != null) {
      await _authLocal.clearSession();
    }

    return const Error(UserNotFoundFailure());
  }

  @override
  Future<Result<UserEntity>> signInWithEmail(AuthCredentials credentials) async {
    return _authenticate(() => _authRemote.signInWithEmail(credentials));
  }

  @override
  Future<Result<UserEntity>> registerWithEmail(
    RegisterCredentials credentials,
  ) async {
    return _authenticate(() => _authRemote.registerWithEmail(credentials));
  }

  @override
  Future<Result<UserEntity>> signInWithGoogle() async {
    return _authenticate(_authRemote.signInWithGoogle);
  }

  @override
  Future<Result<UserEntity>> signInAnonymously() async {
    return _authenticate(_authRemote.signInAnonymously);
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _authRemote.signOut();
      await _authLocal.clearSession();
      _clearProfileCache();
      return const Success(null);
    } on firebase.FirebaseAuthException catch (error) {
      return Error(mapAuthErrorCode(error.code, message: error.message));
    } on Exception catch (error) {
      return Error(UnknownAuthFailure(error.toString()));
    }
  }

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    try {
      await _authRemote.sendPasswordResetEmail(email);
      return const Success(null);
    } on firebase.FirebaseAuthException catch (error) {
      return Error(mapAuthErrorCode(error.code, message: error.message));
    } on Exception catch (error) {
      return Error(UnknownAuthFailure(error.toString()));
    }
  }

  @override
  Future<Result<void>> deleteAccount() async {
    try {
      await _authRemote.deleteAccount();
      await _authLocal.clearSession();
      return const Success(null);
    } on firebase.FirebaseAuthException catch (error) {
      return Error(mapAuthErrorCode(error.code, message: error.message));
    } on Exception catch (error) {
      return Error(AccountDeleteFailure(error.toString()));
    }
  }

  @override
  Future<Result<UserEntity>> getCurrentUserProfile() async {
    final firebaseUser = _authRemote.currentFirebaseUser;
    if (firebaseUser == null) {
      return const Error(UserNotFoundFailure());
    }

    try {
      final user = await _resolveUser(firebaseUser);
      return Success(user);
    } on Exception catch (error) {
      return Error(UnknownAuthFailure(error.toString()));
    }
  }

  Future<Result<UserEntity>> _authenticate(
    Future<firebase.UserCredential> Function() signIn,
  ) async {
    try {
      final credential = await signIn();
      final user = await _resolveUser(credential.user);
      await _authLocal.saveSession(user);
      return Success(user);
    } on firebase.FirebaseAuthException catch (error) {
      return Error(mapAuthErrorCode(error.code, message: error.message));
    } on Exception catch (error) {
      return Error(UnknownAuthFailure(error.toString()));
    }
  }

  Future<UserEntity> _resolveUser(firebase.User? firebaseUser) async {
    if (firebaseUser == null) {
      throw const UserNotFoundException();
    }

    if (_cachedProfileUid == firebaseUser.uid && _cachedProfile != null) {
      return _cachedProfile!;
    }

    if (!_ensuredProfileUids.contains(firebaseUser.uid)) {
      await _userRemote.ensureUserProfile(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? 'Player',
        photoUrl: firebaseUser.photoURL,
        isAnonymous: firebaseUser.isAnonymous,
      );
      _ensuredProfileUids.add(firebaseUser.uid);
    }

    final profile = await _userRemote.getUserProfile(firebaseUser.uid);

    final entity = profile != null
        ? UserMapper.toEntity(
            profile,
            isAnonymous: firebaseUser.isAnonymous,
            emailVerified: firebaseUser.emailVerified,
          )
        : UserMapper.fromFirebaseUser(
            uid: firebaseUser.uid,
            email: firebaseUser.email,
            displayName: firebaseUser.displayName,
            photoUrl: firebaseUser.photoURL,
            isAnonymous: firebaseUser.isAnonymous,
            emailVerified: firebaseUser.emailVerified,
          );

    await _authLocal.saveSession(entity);
    _cachedProfileUid = firebaseUser.uid;
    _cachedProfile = entity;
    return entity;
  }

  void _clearProfileCache() {
    _cachedProfileUid = null;
    _cachedProfile = null;
    _ensuredProfileUids.clear();
  }

  Future<UserEntity?> _mapFirebaseUser(firebase.User? firebaseUser) async {
    if (firebaseUser == null) {
      _clearProfileCache();
      unawaited(_authLocal.clearSession());
      return null;
    }
    try {
      return await _resolveUser(firebaseUser);
    } on UserNotFoundException {
      return null;
    }
  }
}

/// Internal exception when Firebase user is unexpectedly null.
final class UserNotFoundException implements Exception {
  const UserNotFoundException();
}
