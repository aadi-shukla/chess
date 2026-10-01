import 'dart:async';

import 'package:chess/app/theme/app_breakpoints.dart';
import 'package:chess/features/game/presentation/controllers/offline_game_controller.dart';
import 'package:chess/features/game/presentation/widgets/chess_board_widget.dart';
import 'package:chess/features/game/presentation/widgets/chess_clock_widget.dart';
import 'package:chess/features/game/presentation/widgets/move_history_panel.dart';
import 'package:chess/features/game/presentation/widgets/promotion_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Offline chess screen for PvP and PvAI modes.
class OfflineGamePage extends GetView<OfflineGameController> {
  const OfflineGamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OfflineGameController>(
      id: OfflineGameController.chromeId,
      builder: (c) {
        if (c.pendingPromotionFrom != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (c.pendingPromotionFrom != null && !(Get.isDialogOpen ?? false)) {
              Get.dialog<void>(
                const OfflinePromotionDialog(),
                barrierDismissible: false,
              );
            }
          });
        }

        if (c.shouldShowGameOverDialog) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (c.shouldShowGameOverDialog && !(Get.isDialogOpen ?? false)) {
              c.markGameOverDialogShown();
              Get.dialog<void>(
                _GameOverDialog(controller: c),
                barrierDismissible: false,
              );
            }
          });
        }

        final isWide = AppBreakpoints.isDesktop(context);
        final title = c.isVsAi ? 'vs Computer' : 'Local Game';

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              if (c.isAiThinking)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Chip(
                    avatar: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    label: Text('AI thinking'),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.flip_camera_android_outlined),
                tooltip: 'Flip board',
                onPressed: controller.toggleBoardFlip,
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'new':
                      controller.newGame();
                    case 'fen':
                      controller.copyFen();
                      _showSnack(context, 'FEN copied');
                    case 'pgn':
                      controller.copyPgn();
                      _showSnack(context, 'PGN copied');
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'new', child: Text('New game')),
                  const PopupMenuItem(value: 'fen', child: Text('Copy FEN')),
                  const PopupMenuItem(value: 'pgn', child: Text('Copy PGN')),
                ],
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: AppBreakpoints.pagePadding(context),
              child: isWide ? _wideLayout(context) : _narrowLayout(context),
            ),
          ),
          bottomNavigationBar: _bottomBar(context),
        );
      },
    );
  }

  Widget _narrowLayout(BuildContext context) {
    return Column(
      children: [
        const ChessClockWidget(),
        if (controller.statusMessage != null) ...[
          const SizedBox(height: 8),
          _StatusBanner(message: controller.statusMessage!),
        ],
        const SizedBox(height: 12),
        const Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: ChessBoardWidget<OfflineGameController>(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const MoveHistoryPanel(),
          ),
        ),
      ],
    );
  }

  Widget _wideLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              const ChessClockWidget(),
              if (controller.statusMessage != null) ...[
                const SizedBox(height: 8),
                _StatusBanner(message: controller.statusMessage!),
              ],
              const Spacer(),
              const AspectRatio(
                aspectRatio: 1,
                child: ChessBoardWidget<OfflineGameController>(),
              ),
              const Spacer(),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: SizedBox(
            height: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const MoveHistoryPanel(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: controller.canUndo ? controller.undo : null,
                icon: const Icon(Icons.undo),
                label: const Text('Undo'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: controller.canRedo ? controller.redo : null,
                icon: const Icon(Icons.redo),
                label: const Text('Redo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
      content: Text(message),
      actions: const [SizedBox.shrink()],
    );
  }
}

class _GameOverDialog extends StatelessWidget {
  const _GameOverDialog({required this.controller});

  final OfflineGameController controller;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(controller.gameOverTitle),
      content: Text(controller.statusMessage ?? 'Game over'),
      actions: [
        TextButton(
          onPressed: () => Get.back<void>(),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: () {
            Get.back<void>();
            unawaited(controller.newGame());
          },
          child: const Text('New game'),
        ),
      ],
    );
  }
}
