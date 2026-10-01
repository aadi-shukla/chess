import 'package:chess/features/game/presentation/controllers/offline_game_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Scrollable SAN move list for the current game.
class MoveHistoryPanel extends StatelessWidget {
  const MoveHistoryPanel({
    super.key,
    this.moves,
    this.scrollable = false,
  });

  final List<String>? moves;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    if (moves != null) {
      return _MoveList(moves: moves!, scrollable: scrollable);
    }

    return GetBuilder<OfflineGameController>(
      id: OfflineGameController.movesId,
      builder: (controller) {
        return _MoveList(
          moves: controller.moveHistory,
          scrollable: scrollable,
        );
      },
    );
  }
}

class _MoveList extends StatelessWidget {
  const _MoveList({required this.moves, required this.scrollable});

  final List<String> moves;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    if (moves.isEmpty) {
      return Center(
        child: Text(
          'No moves yet',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    final list = ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: (moves.length + 1) ~/ 2,
      itemBuilder: (context, index) {
        final moveNumber = index + 1;
        final whiteIndex = index * 2;
        final blackIndex = whiteIndex + 1;
        final white = moves[whiteIndex];
        final black = blackIndex < moves.length ? moves[blackIndex] : null;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  '$moveNumber.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Expanded(child: Text(white)),
              Expanded(child: Text(black ?? '')),
            ],
          ),
        );
      },
    );

    if (scrollable) return list;
    return SizedBox(height: 160, child: list);
  }
}
