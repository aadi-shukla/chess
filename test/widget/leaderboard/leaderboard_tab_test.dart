import 'package:chess/features/leaderboard/presentation/widgets/leaderboard_tab.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_harness.dart';

void main() {
  testWidgets('LeaderboardTab shows Firebase required message when offline bootstrap',
      (tester) async {
    await tester.pumpWidget(
      TestHarness.themed(const LeaderboardTab()),
    );

    expect(find.text('Leaderboards require Firebase.'), findsOneWidget);
  });
}
