import 'package:chess/features/splash/presentation/pages/splash_page.dart';
import 'package:chess/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart';

void main() {
  group('Golden — SplashPage', () {
    testWidgets('light theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: TestHarness.testLight(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SplashPage(),
        ),
      );
      await tester.pump();

      await expectLater(
        find.byType(SplashPage),
        matchesGoldenFile('splash_page_light.png'),
      );
    });
  });
}
