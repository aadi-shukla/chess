import 'package:chess/chess_engine/chess_engine.dart';
import 'package:chess/features/online/presentation/controllers/online_game_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Clock display for online games — reactive millis, scoped active-state rebuilds.
class OnlineChessClockWidget extends StatelessWidget {
  const OnlineChessClockWidget({super.key});

  static String _format(int millis) {
    final totalSeconds = (millis / 1000).ceil().clamp(0, 99999);
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OnlineGameController>(
      id: OnlineGameController.clockId,
      builder: (controller) {
        final side = controller.position.sideToMove;
        final whiteActive = side == ChessColor.white && !controller.isGameOver;
        final blackActive = side == ChessColor.black && !controller.isGameOver;

        return RepaintBoundary(
          child: Row(
            children: [
              Expanded(
                child: Obx(
                  () => _ClockCard(
                    label: 'Black',
                    time: _format(controller.blackMillisRx.value),
                    isActive: blackActive,
                    isLow: controller.blackMillisRx.value < 60000,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => _ClockCard(
                    label: 'White',
                    time: _format(controller.whiteMillisRx.value),
                    isActive: whiteActive,
                    isLow: controller.whiteMillisRx.value < 60000,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ClockCard extends StatelessWidget {
  const _ClockCard({
    required this.label,
    required this.time,
    required this.isActive,
    required this.isLow,
  });

  final String label;
  final String time;
  final bool isActive;
  final bool isLow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: isActive
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(
              time,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
                color: isLow ? theme.colorScheme.error : null,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
