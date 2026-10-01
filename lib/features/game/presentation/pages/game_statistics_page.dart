import 'package:chess/features/game/presentation/controllers/game_settings_controller.dart';
import 'package:chess/features/game/presentation/controllers/play_tab_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Displays offline game statistics.
class GameStatisticsPage extends GetView<PlayTabController> {
  const GameStatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<GameSettingsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.reload,
          ),
        ],
      ),
      body: GetBuilder<PlayTabController>(
        builder: (c) {
          if (c.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = c.stats;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Section(
                title: 'Player vs Player',
                children: [
                  _StatRow(label: 'Games played', value: '${stats.pvpGames}'),
                  _StatRow(label: 'White wins', value: '${stats.pvpWhiteWins}'),
                  _StatRow(label: 'Black wins', value: '${stats.pvpBlackWins}'),
                  _StatRow(label: 'Draws', value: '${stats.pvpDraws}'),
                ],
              ),
              const SizedBox(height: 24),
              _Section(
                title: 'Player vs AI',
                children: [
                  _StatRow(label: 'Games played', value: '${stats.pvAiGames}'),
                  _StatRow(label: 'Wins', value: '${stats.pvAiWins}'),
                  _StatRow(label: 'Losses', value: '${stats.pvAiLosses}'),
                  _StatRow(label: 'Draws', value: '${stats.pvAiDraws}'),
                ],
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Reset statistics?'),
                      content: const Text(
                        'This clears all offline game statistics.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed ?? false) {
                    await settings.resetStatistics();
                    await controller.reload();
                  }
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Reset statistics'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
