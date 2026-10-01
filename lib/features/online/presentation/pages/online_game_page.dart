import 'dart:async';

import 'package:chess/app/theme/app_breakpoints.dart';
import 'package:chess/features/game/presentation/widgets/chess_board_widget.dart';
import 'package:chess/features/game/presentation/widgets/move_history_panel.dart';
import 'package:chess/features/game/presentation/widgets/online_chess_clock_widget.dart';
import 'package:chess/features/game/presentation/widgets/promotion_dialog.dart';
import 'package:chess/features/online/presentation/controllers/online_game_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Realtime online chess screen.
class OnlineGamePage extends GetView<OnlineGameController> {
  const OnlineGamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OnlineGameController>(
      id: OnlineGameController.chromeId,
      builder: (c) {
        if (c.pendingPromotionFrom != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (c.pendingPromotionFrom != null && !(Get.isDialogOpen ?? false)) {
              Get.dialog<void>(
                const PromotionDialog<OnlineGameController>(),
              );
            }
          });
        }

        final isWide = AppBreakpoints.isDesktop(context);
        final modeLabel = c.remoteGame?.isRated ?? false ? 'Rated' : 'Casual';

        return Scaffold(
          appBar: AppBar(
            title: Text('Online · $modeLabel'),
            actions: [
              if (c.isSubmittingMove)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Chip(
                    avatar: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    label: Text('Sending…'),
                  ),
                ),
              if (!c.isOnline)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Chip(
                    avatar: Icon(Icons.cloud_off, size: 16),
                    label: Text('Offline'),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.flip_camera_android_outlined),
                tooltip: 'Flip board',
                onPressed: c.toggleBoardFlip,
              ),
              if (!c.isGameOver) ...[
                IconButton(
                  icon: const Icon(Icons.handshake_outlined),
                  tooltip: 'Offer draw',
                  onPressed: c.isMyTurn ? () => unawaited(c.offerDraw()) : null,
                ),
                IconButton(
                  icon: const Icon(Icons.flag_outlined),
                  tooltip: 'Resign',
                  onPressed: () => _confirmResign(context, c),
                ),
              ],
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: AppBreakpoints.pagePadding(context),
              child: isWide ? _wideLayout(c) : _narrowLayout(c),
            ),
          ),
        );
      },
    );
  }

  Widget _narrowLayout(OnlineGameController c) {
    return Column(
      children: [
        const OnlineChessClockWidget(),
        if (c.statusMessage != null) ...[
          const SizedBox(height: 8),
          _StatusBanner(message: c.statusMessage!),
        ],
        if (c.hasIncomingDrawOffer) ...[
          const SizedBox(height: 8),
          _DrawOfferBar(controller: c),
        ],
        const SizedBox(height: 12),
        const Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: ChessBoardWidget<OnlineGameController>(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: MoveHistoryPanel(
            moves: c.moveHistory,
            scrollable: true,
          ),
        ),
      ],
    );
  }

  Widget _wideLayout(OnlineGameController c) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              const OnlineChessClockWidget(),
              if (c.statusMessage != null) ...[
                const SizedBox(height: 8),
                _StatusBanner(message: c.statusMessage!),
              ],
              if (c.hasIncomingDrawOffer) ...[
                const SizedBox(height: 8),
                _DrawOfferBar(controller: c),
              ],
              const SizedBox(height: 12),
              const Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ChessBoardWidget<OnlineGameController>(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: MoveHistoryPanel(moves: c.moveHistory, scrollable: true),
        ),
      ],
    );
  }

  Future<void> _confirmResign(
    BuildContext context,
    OnlineGameController c,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resign?'),
        content: const Text('You will lose this game.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Resign'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await c.resign();
    }
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class _DrawOfferBar extends StatelessWidget {
  const _DrawOfferBar({required this.controller});

  final OnlineGameController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Text('Draw offer received')),
        TextButton(
          onPressed: () => unawaited(controller.declineDraw()),
          child: const Text('Decline'),
        ),
        FilledButton(
          onPressed: () => unawaited(controller.acceptDraw()),
          child: const Text('Accept'),
        ),
      ],
    );
  }
}
