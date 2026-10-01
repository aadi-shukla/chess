import 'package:chess/features/auth/presentation/widgets/auth_form_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_harness.dart';

void main() {
  group('AuthFormCardInner widget', () {
    testWidgets('renders title, subtitle, and child', (tester) async {
      await tester.pumpWidget(
        TestHarness.themed(
          const AuthFormCardInner(
            title: 'Welcome back',
            subtitle: 'Sign in to continue',
            child: TextField(key: Key('email')),
          ),
        ),
      );

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Sign in to continue'), findsOneWidget);
      expect(find.byKey(const Key('email')), findsOneWidget);
    });

    testWidgets('header has semantics', (tester) async {
      await tester.pumpWidget(
        TestHarness.themed(
          const AuthFormCardInner(
            title: 'Register',
            subtitle: 'Create your account',
            child: SizedBox(),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.text('Register'));
      expect(semantics.hasFlag(SemanticsFlag.isHeader), isTrue);
    });
  });
}
