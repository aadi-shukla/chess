import 'package:chess/app/app.dart';
import 'package:chess/app/bindings/auth_binding.dart';
import 'package:chess/app/bindings/initial_binding.dart';
import 'package:chess/core/utils/app_logger.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

void main() {
  setUp(() async {
    AppLogger.configure(levelName: 'debug');
    Hive.init('test_hive');
    InitialBinding().dependencies();
    AuthBinding.register();
    await InitialBinding.initializeAsyncServices();
    await AuthBinding.initializeSession();
  });

  tearDown(() async {
    await Hive.close();
    Get.reset();
  });

  testWidgets('ChessApp renders splash screen', (tester) async {
    await tester.pumpWidget(const ChessApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ChessApp), findsOneWidget);

    // Tear down the widget tree so the splash controller is disposed and its
    // pending navigation timer is cancelled (avoids leaking a pending timer).
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
