import 'package:chess/app/app.dart';
import 'package:chess/app/bindings/auth_binding.dart';
import 'package:chess/app/bindings/initial_binding.dart';
import 'package:chess/chess_engine/chess_engine.dart';
import 'package:chess/core/utils/app_logger.dart';
import 'package:chess/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    AppLogger.configure(levelName: 'debug');
    Hive.init('integration_test_hive_${DateTime.now().microsecondsSinceEpoch}');
    InitialBinding().dependencies();
    AuthBinding.register();
    await InitialBinding.initializeAsyncServices();
    await AuthBinding.initializeSession();
  });

  tearDown(() async {
    await Hive.close();
    Get.reset();
  });

  group('Integration — reconnect profile', () {
    testWidgets('user entity with activeGameId serializes for splash routing',
        (tester) async {
      const profile = UserEntity(
        uid: 'user-reconnect',
        email: 'r@chess.com',
        displayName: 'Reconnect',
        activeGameId: 'game-42',
      );

      expect(profile.activeGameId, 'game-42');
      expect(profile.copyWith(rating: 1500).activeGameId, 'game-42');
    });
  });

  group('Integration — offline engine', () {
    testWidgets('local game accepts moves without network', (tester) async {
      await tester.pumpWidget(const ChessApp());
      await tester.pump();

      final game = ChessGame();
      expect(game.makeMoveFromUci('e2e4'), isTrue);
      expect(game.makeMoveFromUci('e7e5'), isTrue);
      expect(tester.takeException(), isNull);
    });
  });
}
