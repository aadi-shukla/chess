import 'package:chess/chess_engine/chess_engine.dart';
import 'package:chess/features/online/domain/entities/online_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OnlineGame entity — multiplayer', () {
    const game = OnlineGame(
      id: 'g1',
      whiteUid: 'w1',
      blackUid: 'b1',
      status: 'active',
      fen: FenParser.startingFen,
      turn: 'white',
      version: 1,
      timeControl: '10+0',
      mode: 'rated',
      moveHistory: [],
      whiteMillis: 600000,
      blackMillis: 600000,
      incrementMillis: 0,
    );

    test('turn and color helpers', () {
      expect(game.isMyTurn('w1'), isTrue);
      expect(game.isMyTurn('b1'), isFalse);
      expect(game.colorFor('w1'), ChessColor.white);
      expect(game.colorFor('b1'), ChessColor.black);
    });

    test('non-participant throws', () {
      expect(() => game.colorFor('spectator'), throwsStateError);
    });

    test('finished game flags', () {
      const finished = OnlineGame(
        id: 'g2',
        whiteUid: 'w1',
        blackUid: 'b1',
        status: 'finished',
        fen: FenParser.startingFen,
        turn: 'white',
        version: 10,
        timeControl: '5+0',
        mode: 'casual',
        moveHistory: [],
        whiteMillis: 0,
        blackMillis: 120000,
        incrementMillis: 0,
        result: 'black_wins',
        endReason: 'checkmate',
      );

      expect(finished.isFinished, isTrue);
      expect(finished.isActive, isFalse);
      expect(finished.isRated, isFalse);
    });
  });

  group('OnlineGame — edge cases', () {
    test('draw offer pending state', () {
      const game = OnlineGame(
        id: 'g3',
        whiteUid: 'w1',
        blackUid: 'b1',
        status: 'active',
        fen: FenParser.startingFen,
        turn: 'black',
        version: 5,
        timeControl: '15+10',
        mode: 'rated',
        moveHistory: [],
        whiteMillis: 400000,
        blackMillis: 380000,
        incrementMillis: 10000,
        drawOffer: DrawOffer(offeredBy: 'w1', status: 'pending'),
      );

      expect(game.drawOffer?.isPending, isTrue);
      expect(game.isRated, isTrue);
    });
  });
}
