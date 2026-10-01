import 'package:chess/features/auth/domain/validators/auth_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthValidator.validateEmail', () {
    test('rejects empty email', () {
      expect(AuthValidator.validateEmail(''), isNotNull);
    });

    test('rejects invalid format', () {
      expect(AuthValidator.validateEmail('not-an-email'), isNotNull);
    });

    test('accepts valid email', () {
      expect(AuthValidator.validateEmail('player@chess.com'), isNull);
    });
  });

  group('AuthValidator.validatePassword', () {
    test('rejects short password', () {
      expect(AuthValidator.validatePassword('abc'), isNotNull);
    });

    test('registration requires letter and number', () {
      expect(
        AuthValidator.validatePassword('12345678', isRegistration: true),
        isNotNull,
      );
      expect(
        AuthValidator.validatePassword('abcdefgh', isRegistration: true),
        isNotNull,
      );
    });

    test('accepts strong registration password', () {
      expect(
        AuthValidator.validatePassword('Password1', isRegistration: true),
        isNull,
      );
    });
  });

  group('AuthValidator.validateDisplayName', () {
    test('rejects single character name', () {
      expect(AuthValidator.validateDisplayName('A'), isNotNull);
    });

    test('accepts valid display name', () {
      expect(AuthValidator.validateDisplayName('Grandmaster'), isNull);
      expect(AuthValidator.validateDisplayName("O'Brien"), isNull);
    });

    test('rejects invalid characters in display name', () {
      expect(AuthValidator.validateDisplayName('Bad<script>'), isNotNull);
      expect(AuthValidator.validateDisplayName('@@@'), isNotNull);
    });
  });

  group('AuthValidator.validateConfirmPassword', () {
    test('rejects mismatch', () {
      expect(
        AuthValidator.validateConfirmPassword('Password1', 'Password2'),
        isNotNull,
      );
    });

    test('accepts match', () {
      expect(
        AuthValidator.validateConfirmPassword('Password1', 'Password1'),
        isNull,
      );
    });
  });
}
