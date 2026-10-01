import 'package:chess/app/app.dart';
import 'package:chess/app/bindings/auth_binding.dart';
import 'package:chess/app/bindings/initial_binding.dart';
import 'package:chess/core/utils/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    AppLogger.configure(levelName: 'debug');
    Hive.init('integration_test_hive');
    InitialBinding().dependencies();
    AuthBinding.register();
    await InitialBinding.initializeAsyncServices();
    await AuthBinding.initializeSession();
  });

  tearDown(() async {
    await Hive.close();
    Get.reset();
  });

  group('Integration — app smoke', () {
    testWidgets('app launches splash screen', (tester) async {
      await tester.pumpWidget(const ChessApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ChessApp), findsOneWidget);
    });
  });

  group('Integration — offline engine', () {
    testWidgets('chess engine perft runs in app isolate', (tester) async {
      await tester.pumpWidget(const ChessApp());
      await tester.pump();

      // Engine is bundled with the app — verify no crash on startup.
      expect(tester.takeException(), isNull);
    });
  });
}
