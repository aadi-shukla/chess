import 'package:chess/features/auth/presentation/widgets/auth_form_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart';

void main() {
  group('Golden — AuthFormCardInner', () {
    testWidgets('light theme', (tester) async {
      await tester.pumpWidget(
        TestHarness.themed(
          const AuthFormCardInner(
            title: 'Sign in',
            subtitle: 'Welcome back to Chess',
            child: SizedBox(height: 48),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(AuthFormCardInner),
        matchesGoldenFile('auth_form_card_light.png'),
      );
    });
  });
}
