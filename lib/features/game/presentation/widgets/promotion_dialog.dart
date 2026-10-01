import 'package:chess/chess_engine/chess_engine.dart';
import 'package:chess/features/game/presentation/board/chess_board_host.dart';
import 'package:chess/features/game/presentation/controllers/offline_game_controller.dart';
import 'package:chess/features/game/presentation/widgets/chess_piece_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Piece selection dialog for pawn promotion.
class PromotionDialog<C extends GetxController> extends StatelessWidget {
  const PromotionDialog({super.key});

  static const _options = [
    PieceType.queen,
    PieceType.rook,
    PieceType.bishop,
    PieceType.knight,
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<C>();
    final host = controller as PromotionHost;
    final color = host.position.sideToMove;

    return AlertDialog(
      title: const Text('Promote pawn'),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final type in _options)
            IconButton(
              onPressed: () {
                host.completePromotion(type);
                Get.back<void>();
              },
              icon: ChessPieceWidget(
                piece: Piece(color: color, type: type),
                size: 48,
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            host.cancelPromotion();
            Get.back<void>();
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

typedef OfflinePromotionDialog = PromotionDialog<OfflineGameController>;
