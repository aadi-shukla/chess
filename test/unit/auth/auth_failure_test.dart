import 'package:chess/features/auth/domain/failures/auth_failure.dart';
import 'package:chess/features/auth/presentation/utils/auth_failure_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthFailureMapper', () {
    test('maps invalid email failure', () {
      const failure = InvalidEmailFailure();
      expect(
        AuthFailureMapper.message(failure),
        contains('valid email'),
      );
    });

    test('maps requires recent login', () {
      const failure = RequiresRecentLoginFailure();
      expect(
        AuthFailureMapper.message(failure),
        contains('sign in again'),
      );
    });
  });

  group('mapAuthErrorCode', () {
    test('maps invalid-email', () {
      expect(mapAuthErrorCode('invalid-email'), isA<InvalidEmailFailure>());
    });

    test('maps admin-restricted-operation', () {
      expect(
        mapAuthErrorCode('admin-restricted-operation'),
        isA<SignUpDisabledFailure>(),
      );
    });

    test('maps operation-not-allowed', () {
      expect(
        mapAuthErrorCode('operation-not-allowed'),
        isA<AuthProviderDisabledFailure>(),
      );
    });

    test('maps unknown codes', () {
      final failure = mapAuthErrorCode('custom', message: 'Custom');
      expect(failure, isA<UnknownAuthFailure>());
    });
  });
}
