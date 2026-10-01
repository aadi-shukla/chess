import 'package:chess/features/splash/presentation/pages/splash_page.dart';
import 'package:chess/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_harness.dart';

void main() {
  testWidgets('SplashPage shows title and loading indicator', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TestHarness.testLight(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SplashPage(),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.grid_on_rounded), findsOneWidget);
  });
}
