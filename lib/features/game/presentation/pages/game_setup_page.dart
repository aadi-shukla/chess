import 'package:chess/app/routes/app_routes.dart';
import 'package:chess/chess_engine/chess_engine.dart';
import 'package:chess/features/game/domain/entities/board_theme.dart';
import 'package:chess/features/game/domain/entities/game_config.dart';
import 'package:chess/features/game/domain/entities/game_launch_args.dart';
import 'package:chess/features/game/domain/entities/game_mode.dart';
import 'package:chess/features/game/presentation/controllers/game_settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Pre-game setup: mode, time control, AI options.
class GameSetupPage extends StatefulWidget {
  const GameSetupPage({
    required this.initialMode,
    super.key,
  });

  final GameMode initialMode;

  @override
  State<GameSetupPage> createState() => _GameSetupPageState();
}

class _GameSetupPageState extends State<GameSetupPage> {
  late GameMode _mode;
  late int _minutes;
  late int _increment;
  late AiDifficulty _difficulty;
  late ChessColor _humanColor;
  late BoardTheme _boardTheme;

  @override
  void initState() {
    super.initState();
    final settings = Get.find<GameSettingsController>();
    _mode = widget.initialMode;
    _minutes = settings.defaultMinutes;
    _increment = settings.defaultIncrement;
    _difficulty = settings.defaultAiDifficulty;
    _humanColor = ChessColor.white;
    _boardTheme = settings.boardTheme;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_mode.label),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Time control', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _minutes,
                  decoration: const InputDecoration(
                    labelText: 'Minutes',
                    border: OutlineInputBorder(),
                  ),
                  items: const [3, 5, 10, 15, 30]
                      .map(
                        (m) => DropdownMenuItem(value: m, child: Text('$m min')),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _minutes = v ?? _minutes),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _increment,
                  decoration: const InputDecoration(
                    labelText: 'Increment',
                    border: OutlineInputBorder(),
                  ),
                  items: const [0, 1, 2, 3, 5]
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s == 0 ? 'None' : '${s}s'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _increment = v ?? _increment),
                ),
              ),
            ],
          ),
          if (_mode == GameMode.playerVsAi) ...[
            const SizedBox(height: 24),
            Text('AI difficulty', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<AiDifficulty>(
              segments: AiDifficulty.values
                  .map(
                    (d) => ButtonSegment(
                      value: d,
                      label: Text(d.label, style: const TextStyle(fontSize: 11)),
                    ),
                  )
                  .toList(),
              selected: {_difficulty},
              onSelectionChanged: (s) => setState(() => _difficulty = s.first),
            ),
            const SizedBox(height: 24),
            Text('Your color', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<ChessColor>(
              segments: const [
                ButtonSegment(value: ChessColor.white, label: Text('White')),
                ButtonSegment(value: ChessColor.black, label: Text('Black')),
              ],
              selected: {_humanColor},
              onSelectionChanged: (s) => setState(() => _humanColor = s.first),
            ),
          ],
          const SizedBox(height: 24),
          Text('Board theme', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: BoardTheme.values.map((t) {
              final selected = _boardTheme == t;
              return ChoiceChip(
                label: Text(t.label),
                selected: selected,
                onSelected: (_) => setState(() => _boardTheme = t),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _startGame,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text('Start game'),
            ),
          ),
        ],
      ),
    );
  }

  void _startGame() {
    final config = GameConfig(
      mode: _mode,
      minutes: _minutes,
      incrementSeconds: _increment,
      aiDifficulty: _difficulty,
      humanColor: _humanColor,
      boardTheme: _boardTheme,
    );

    Get.offNamed<void>(
      AppRoutes.offlineGame,
      arguments: GameLaunchArgs(config: config),
    );
  }
}
