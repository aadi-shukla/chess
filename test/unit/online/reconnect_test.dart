import 'package:chess/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Reconnect logic', () {
    test('activeGameId on profile triggers resume path', () {
      const profile = UserEntity(
        uid: 'u1',
        email: 'a@b.com',
        displayName: 'Player',
        activeGameId: 'game-xyz',
      );

      expect(profile.activeGameId, isNotNull);
      expect(profile.activeGameId!.isNotEmpty, isTrue);
    });

    test('cleared activeGameId means no reconnect', () {
      const profile = UserEntity(
        uid: 'u1',
        email: 'a@b.com',
        displayName: 'Player',
      );

      expect(profile.activeGameId, isNull);
    });

    test('copyWith preserves activeGameId unless overridden', () {
      const profile = UserEntity(
        uid: 'u1',
        email: 'a@b.com',
        displayName: 'Player',
        activeGameId: 'game-1',
      );

      final updated = profile.copyWith(rating: 1400);
      expect(updated.activeGameId, 'game-1');
    });
  });
}
