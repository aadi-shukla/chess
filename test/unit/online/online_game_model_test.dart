import 'package:chess/chess_engine/chess_engine.dart';
import 'package:chess/features/online/data/models/online_game_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OnlineGameModel', () {
    test('parses Firestore game document with clocks and draw offer',
        () async {
      final firestore = FakeFirebaseFirestore();
      final doc = firestore.collection('games').doc('game-1');
      await doc.set({
        'whiteUid': 'w1',
        'blackUid': 'b1',
        'status': 'active',
        'fen': 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
        'turn': 'black',
        'version': 2,
        'timeControl': '10+5',
        'mode': 'rated',
        'whiteMillis': 598000,
        'blackMillis': 600000,
        'incrementMillis': 5000,
        'moveHistory': [
          {
            'san': 'e4',
            'from': 'e2',
            'to': 'e4',
            'promotion': null,
            'byUid': 'w1',
          },
        ],
        'drawOffer': {'offeredBy': 'b1', 'status': 'pending'},
        'lastMoveAt': Timestamp.fromMillisecondsSinceEpoch(1_700_000_000_000),
      });
      final snapshot = await doc.get();

      final model = OnlineGameModel.fromFirestore(snapshot);
      final entity = OnlineGameMapper.toEntity(model);

      expect(entity.id, 'game-1');
      expect(entity.version, 2);
      expect(entity.isRated, isTrue);
      expect(entity.moveHistory, hasLength(1));
      expect(entity.moveHistory.first.san, 'e4');
      expect(entity.drawOffer?.offeredBy, 'b1');
      expect(entity.isMyTurn('b1'), isTrue);
      expect(entity.colorFor('w1'), ChessColor.white);
    });
  });
}
