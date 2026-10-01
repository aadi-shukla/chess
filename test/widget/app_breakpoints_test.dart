import 'package:chess/app/theme/app_breakpoints.dart';
import 'package:chess/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

Widget _responsiveApp({required Widget home}) {
  return MaterialApp(
    builder: (context, child) => ResponsiveBreakpoints.builder(
      child: child!,
      breakpoints: const [
        Breakpoint(
          start: 0,
          end: AppConstants.mobileBreakpoint,
          name: MOBILE,
        ),
        Breakpoint(
          start: AppConstants.mobileBreakpoint + 1,
          end: AppConstants.tabletBreakpoint,
          name: TABLET,
        ),
        Breakpoint(
          start: AppConstants.tabletBreakpoint + 1,
          end: AppConstants.desktopBreakpoint,
          name: DESKTOP,
        ),
        Breakpoint(
          start: AppConstants.desktopBreakpoint + 1,
          end: double.infinity,
          name: '4K',
        ),
      ],
    ),
    home: home,
  );
}

void main() {
  testWidgets('AppBreakpoints adapts content width on mobile', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_responsiveApp(home: const SizedBox()));
    await tester.pump();

    final context = tester.element(find.byType(SizedBox));
    expect(AppBreakpoints.contentMaxWidth(context), double.infinity);
  });

  testWidgets('AppBreakpoints caps width on desktop', (tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_responsiveApp(home: const SizedBox()));
    await tester.pump();

    final context = tester.element(find.byType(SizedBox));
    expect(AppBreakpoints.contentMaxWidth(context), 960);
  });
}
