import 'package:chess/features/game/domain/entities/game_statistics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pvAiGames sums outcomes', () {
    const stats = GameStatistics(pvAiWins: 2, pvAiLosses: 3, pvAiDraws: 1);
    expect(stats.pvAiGames, 6);
  });
}
