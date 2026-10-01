import 'dart:async';

import 'package:chess/app/theme/app_breakpoints.dart';
import 'package:chess/app/widgets/responsive_content.dart';
import 'package:chess/chess_engine/chess_engine.dart';
import 'package:chess/features/game/domain/entities/board_theme.dart';
import 'package:chess/features/game/presentation/controllers/game_settings_controller.dart';
import 'package:chess/features/settings/presentation/controllers/settings_controller.dart';
import 'package:chess/features/settings/presentation/controllers/theme_controller.dart';
import 'package:chess/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Application settings including theme and offline game preferences.
class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeController = Get.find<ThemeController>();
    final isWide = AppBreakpoints.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: GetBuilder<GameSettingsController>(
        builder: (game) {
          if (game.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final themeSection = _ThemeSection(
            l10n: l10n,
            themeController: themeController,
            onThemeChanged: controller.setThemeMode,
          );

          final gameSection = _GameSection(l10n: l10n, game: game);

          return ResponsiveContent(
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: themeSection),
                      const SizedBox(width: 24),
                      Expanded(child: gameSection),
                    ],
                  )
                : ListView(
                    children: [
                      themeSection,
                      const SizedBox(height: 24),
                      gameSection,
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _ThemeSection extends StatelessWidget {
  const _ThemeSection({
    required this.l10n,
    required this.themeController,
    required this.onThemeChanged,
  });

  final AppLocalizations l10n;
  final ThemeController themeController;
  final Future<void> Function(ThemeMode) onThemeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.settingsTheme, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Obx(
          () => SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(l10n.settingsThemeLight),
                icon: const Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(l10n.settingsThemeSystem),
                icon: const Icon(Icons.brightness_auto_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(l10n.settingsThemeDark),
                icon: const Icon(Icons.dark_mode_outlined),
              ),
            ],
            selected: {themeController.themeMode.value},
            onSelectionChanged: (selection) {
              unawaited(onThemeChanged(selection.first));
            },
          ),
        ),
      ],
    );
  }
}

class _GameSection extends StatelessWidget {
  const _GameSection({required this.l10n, required this.game});

  final AppLocalizations l10n;
  final GameSettingsController game;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.settingsGameTitle, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: game.defaultMinutes,
          decoration: InputDecoration(labelText: l10n.settingsDefaultTime),
          items: const [3, 5, 10, 15, 30]
              .map((m) => DropdownMenuItem(value: m, child: Text('$m min')))
              .toList(),
          onChanged: (v) {
            if (v != null) unawaited(game.setDefaultMinutes(v));
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: game.defaultIncrement,
          decoration: InputDecoration(labelText: l10n.settingsDefaultIncrement),
          items: const [0, 1, 2, 3, 5]
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(s == 0 ? 'None' : '${s}s'),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) unawaited(game.setDefaultIncrement(v));
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<AiDifficulty>(
          initialValue: game.defaultAiDifficulty,
          decoration: InputDecoration(labelText: l10n.settingsDefaultAiDifficulty),
          items: AiDifficulty.values
              .map((d) => DropdownMenuItem(value: d, child: Text(d.label)))
              .toList(),
          onChanged: (v) {
            if (v != null) unawaited(game.setDefaultAiDifficulty(v));
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<BoardTheme>(
          initialValue: game.boardTheme,
          decoration: InputDecoration(labelText: l10n.settingsBoardTheme),
          items: BoardTheme.values
              .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
              .toList(),
          onChanged: (v) {
            if (v != null) unawaited(game.setBoardTheme(v));
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.settingsHaptics),
          value: game.hapticsEnabled,
          onChanged: (v) => unawaited(game.setHapticsEnabled(v)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.settingsAutoSave),
          subtitle: Text(l10n.settingsAutoSaveDescription),
          value: game.autoSaveEnabled,
          onChanged: (v) => unawaited(game.setAutoSaveEnabled(v)),
        ),
      ],
    );
  }
}
