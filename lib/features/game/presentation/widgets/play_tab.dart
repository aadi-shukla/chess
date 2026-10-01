import 'package:chess/app/routes/app_routes.dart';
import 'package:chess/core/firebase/firebase_bootstrap.dart';
import 'package:chess/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:chess/features/game/domain/entities/game_config.dart';
import 'package:chess/features/game/domain/entities/game_launch_args.dart';
import 'package:chess/features/game/domain/entities/game_mode.dart';
import 'package:chess/features/game/domain/entities/sync_state.dart';
import 'package:chess/features/game/presentation/controllers/game_settings_controller.dart';
import 'package:chess/features/game/presentation/controllers/play_tab_controller.dart';
import 'package:chess/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Play tab: PvP, PvAI, resume, and statistics.
class PlayTab extends GetView<PlayTabController> {
  const PlayTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return GetBuilder<PlayTabController>(
      builder: (c) {
        if (c.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(l10n.navPlay, style: theme.textTheme.displaySmall),
            const SizedBox(height: 8),
            Text(l10n.playOfflineSubtitle, style: theme.textTheme.bodyLarge),
            if (c.canSync) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _syncLabel(l10n, c),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: c.isSyncing ? null : c.syncNow,
                    icon: c.isSyncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_sync_outlined, size: 18),
                    label: Text(l10n.playSyncNow),
                  ),
                ],
              ),
            ],
            if (c.savedGame != null) ...[
              const SizedBox(height: 24),
              Card(
                color: theme.colorScheme.primaryContainer,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _resumeGame(c),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          size: 40,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.playResumeGame,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              Text(
                                l10n.playResumeDescription(
                                  c.savedGame!.moveCount,
                                  c.savedGame!.mode.label,
                                ),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            _GameModeCard(
              icon: Icons.people_outline,
              title: l10n.playLocalGame,
              description: l10n.playLocalGameDescription,
              onTap: () => Get.toNamed<void>(
                AppRoutes.gameSetup,
                arguments: GameMode.playerVsPlayer,
              ),
            ),
            const SizedBox(height: 16),
            _GameModeCard(
              icon: Icons.smart_toy_outlined,
              title: l10n.playVsAi,
              description: l10n.playVsAiDescription,
              onTap: () => Get.toNamed<void>(
                AppRoutes.gameSetup,
                arguments: GameMode.playerVsAi,
              ),
            ),
            const SizedBox(height: 16),
            _GameModeCard(
              icon: Icons.wifi,
              title: l10n.playOnline,
              description: l10n.playOnlineDescription,
              onTap: () {
                if (!FirebaseBootstrap.isInitialized) {
                  Get.snackbar('Online play', l10n.playOnlineUnavailable);
                  return;
                }
                if (!Get.isRegistered<AuthSessionController>() ||
                    (Get.find<AuthSessionController>().user.value?.isAnonymous ?? false)) {
                  Get.snackbar('Online play', l10n.playOnlineSignInRequired);
                  return;
                }
                Get.toNamed<void>(AppRoutes.matchmaking);
              },
            ),
            const SizedBox(height: 16),
            _GameModeCard(
              icon: Icons.bar_chart_outlined,
              title: l10n.playStatistics,
              description: l10n.playStatisticsDescription(
                c.stats.pvpGames + c.stats.pvAiGames,
              ),
              onTap: () => Get.toNamed<void>(AppRoutes.gameStatistics),
            ),
          ],
          ),
        );
      },
    );
  }

  String _syncLabel(AppLocalizations l10n, PlayTabController c) {
    return switch (c.syncState.status) {
      SyncStatus.syncing => l10n.playSyncSyncing,
      SyncStatus.offline => l10n.playSyncOffline,
      SyncStatus.error => l10n.playSyncError,
      SyncStatus.success when c.syncState.lastSyncedAt != null =>
        l10n.playSyncLastSynced(_formatTime(c.syncState.lastSyncedAt!)),
      _ => c.syncState.pendingOperations > 0
          ? l10n.playSyncPending(c.syncState.pendingOperations)
          : l10n.playSyncIdle,
    };
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  void _resumeGame(PlayTabController c) {
    final saved = c.savedGame;
    if (saved == null) return;

    final settings = Get.find<GameSettingsController>();

    Get.toNamed<void>(
      AppRoutes.offlineGame,
      arguments: GameLaunchArgs(
        config: GameConfig(
          mode: saved.mode,
          aiDifficulty: saved.aiDifficulty,
          humanColor: saved.humanColor,
          boardTheme: settings.boardTheme,
        ),
        resume: saved,
      ),
    );
  }
}

class _GameModeCard extends StatelessWidget {
  const _GameModeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 40, color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
