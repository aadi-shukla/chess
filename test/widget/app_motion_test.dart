import 'package:chess/app/theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppMotion respects reduced motion', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              expect(AppMotion.reducedMotion(context), isTrue);
              expect(
                AppMotion.tabSwitch(context),
                Duration.zero,
              );
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  });
}
