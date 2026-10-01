import 'package:chess/core/errors/result.dart';
import 'package:chess/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:chess/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:chess/features/auth/data/datasources/user_remote_datasource.dart';
import 'package:chess/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:chess/features/auth/data/services/auth_service_impl.dart';
import 'package:chess/features/auth/domain/entities/user_entity.dart';
import 'package:chess/features/auth/domain/failures/auth_failure.dart';
import 'package:chess/features/auth/domain/repositories/auth_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_harness.dart';

void main() {
  late AuthRepository repository;
  late AuthLocalDataSource local;
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore firestore;

  setUp(() async {
    await TestHarness.initHive(path: TestHarness.uniqueHivePath('auth'));
    local = AuthLocalDataSource();
    firestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    repository = AuthRepositoryImpl(
      authRemoteDataSource: AuthRemoteDataSource(
        AuthServiceImpl(firebaseAuth: mockAuth),
      ),
      userRemoteDataSource: UserRemoteDataSource(fakeFirestoreService(firestore)),
      authLocalDataSource: local,
    );
  });

  tearDown(() async {
    await local.clearSession();
    await TestHarness.clearHiveBoxes();
  });

  group('AuthRepositoryImpl', () {
    test('restoreSession returns user when Firebase session is active', () async {
      final user = MockUser(
        uid: 'user-1',
        email: 'player@chess.com',
        displayName: 'Player One',
      );
      mockAuth = MockFirebaseAuth(mockUser: user, signedIn: true);

      repository = AuthRepositoryImpl(
        authRemoteDataSource: AuthRemoteDataSource(
          AuthServiceImpl(firebaseAuth: mockAuth),
        ),
        userRemoteDataSource: UserRemoteDataSource(fakeFirestoreService(firestore)),
        authLocalDataSource: local,
      );

      await firestore.collection('users').doc('user-1').set({
        'email': 'player@chess.com',
        'displayName': 'Player One',
        'rating': 1300,
        'stats': {'played': 5, 'wins': 3, 'losses': 2, 'draws': 0},
      });

      final result = await repository.restoreSession();

      expect(result, isA<Success<UserEntity>>());
      expect(result.dataOrNull?.uid, 'user-1');
      expect(result.dataOrNull?.rating, 1300);
    });

    test('restoreSession clears stale cache without Firebase user', () async {
      await local.saveSession(
        const UserEntity(
          uid: 'stale',
          email: 'old@chess.com',
          displayName: 'Stale',
        ),
      );

      final result = await repository.restoreSession();

      expect(result, isA<Error<UserEntity>>());
      expect(result.failureOrNull, isA<UserNotFoundFailure>());
      expect(await local.readSession(), isNull);
    });

    test('signOut clears local session when remote succeeds', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final user = MockUser(uid: 'u1', email: 'a@b.com');
      mockAuth = MockFirebaseAuth(mockUser: user, signedIn: true);
      repository = AuthRepositoryImpl(
        authRemoteDataSource: AuthRemoteDataSource(
          AuthServiceImpl(
            firebaseAuth: mockAuth,
            googleSignIn: _NoopGoogleSignIn(),
          ),
        ),
        userRemoteDataSource: UserRemoteDataSource(fakeFirestoreService(firestore)),
        authLocalDataSource: local,
      );

      await local.saveSession(
        const UserEntity(uid: 'u1', email: 'a@b.com', displayName: 'A'),
      );

      final result = await repository.signOut();

      expect(result, isA<Success<void>>());
      expect(await local.readSession(), isNull);
    });

    test('getCurrentUserProfile returns activeGameId for reconnect', () async {
      final user = MockUser(uid: 'user-2', email: 'r@chess.com');
      mockAuth = MockFirebaseAuth(mockUser: user, signedIn: true);
      repository = AuthRepositoryImpl(
        authRemoteDataSource: AuthRemoteDataSource(
          AuthServiceImpl(firebaseAuth: mockAuth),
        ),
        userRemoteDataSource: UserRemoteDataSource(fakeFirestoreService(firestore)),
        authLocalDataSource: local,
      );

      await firestore.collection('users').doc('user-2').set({
        'email': 'r@chess.com',
        'displayName': 'Reconnect',
        'rating': 1200,
        'activeGameId': 'game-active-99',
        'stats': {'played': 0, 'wins': 0, 'losses': 0, 'draws': 0},
      });

      final result = await repository.getCurrentUserProfile();

      expect(result.dataOrNull?.activeGameId, 'game-active-99');
    });
  });
}

class _NoopGoogleSignIn extends GoogleSignIn {
  @override
  Future<GoogleSignInAccount?> signOut() async => null;
}
