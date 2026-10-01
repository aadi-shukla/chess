import 'package:chess/app/config/env_config.dart';
import 'package:chess/app/routes/app_routes.dart';
import 'package:chess/app/widgets/adaptive_shell.dart';
import 'package:chess/app/widgets/responsive_content.dart';
import 'package:chess/features/auth/presentation/pages/profile_page.dart';
import 'package:chess/features/game/presentation/widgets/play_tab.dart';
import 'package:chess/features/home/presentation/controllers/home_controller.dart';
import 'package:chess/features/leaderboard/presentation/widgets/leaderboard_tab.dart';
import 'package:chess/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Primary application shell with adaptive navigation and animated tabs.
class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final flavorBannerColor = EnvConfig.flavorBannerColor;

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: Text(l10n.appTitle),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsTitle,
            onPressed: () => Get.toNamed<void>(AppRoutes.settings),
          ),
        ],
      ),
      body: Column(
        children: [
          if (flavorBannerColor != null)
            MaterialBanner(
              backgroundColor: flavorBannerColor,
              content: Text(
                l10n.flavorLabel(EnvConfig.flavor),
                style: const TextStyle(color: Colors.white),
              ),
              actions: const [SizedBox.shrink()],
            ),
          Expanded(
            child: GetBuilder<HomeController>(
              builder: (controller) => AdaptiveShell(
                selectedIndex: controller.selectedIndex,
                onDestinationSelected: controller.onDestinationSelected,
                destinations: [
                  ShellDestination(
                    label: l10n.navHome,
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home,
                  ),
                  ShellDestination(
                    label: l10n.navPlay,
                    icon: Icons.sports_esports_outlined,
                    selectedIcon: Icons.sports_esports,
                  ),
                  ShellDestination(
                    label: l10n.navLeaderboard,
                    icon: Icons.leaderboard_outlined,
                    selectedIcon: Icons.leaderboard,
                  ),
                  ShellDestination(
                    label: l10n.navProfile,
                    icon: Icons.person_outline,
                    selectedIcon: Icons.person,
                  ),
                ],
                body: IndexedStack(
                  index: controller.selectedIndex,
                  children: [
                    ResponsiveContent(
                      child: _DashboardTab(
                        l10n: l10n,
                        onNavigate: controller.onDestinationSelected,
                      ),
                    ),
                    const ResponsiveContent(child: PlayTab()),
                    const ResponsiveContent(child: LeaderboardTab()),
                    const ResponsiveContent(child: ProfilePage()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({
    required this.l10n,
    required this.onNavigate,
  });

  final AppLocalizations l10n;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      children: [
        Text(l10n.homeWelcome, style: theme.textTheme.displayLarge),
        const SizedBox(height: 12),
        Text(l10n.homeSubtitle, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 640 ? 2 : 1;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: columns == 2 ? 2.4 : 2.8,
              children: [
                _QuickActionCard(
                  icon: Icons.sports_esports_outlined,
                  title: l10n.navPlay,
                  subtitle: l10n.playOfflineSubtitle,
                  onTap: () => onNavigate(1),
                ),
                _QuickActionCard(
                  icon: Icons.leaderboard_outlined,
                  title: l10n.navLeaderboard,
                  subtitle: l10n.playStatisticsDescription(0),
                  onTap: () => onNavigate(2),
                ),
                _QuickActionCard(
                  icon: Icons.wifi,
                  title: l10n.playOnline,
                  subtitle: l10n.playOnlineDescription,
                  onTap: () => onNavigate(1),
                ),
                _QuickActionCard(
                  icon: Icons.person_outline,
                  title: l10n.navProfile,
                  subtitle: l10n.settingsTitle,
                  onTap: () => onNavigate(3),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: title,
      hint: subtitle,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.35 : 0.55,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(icon, color: theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
