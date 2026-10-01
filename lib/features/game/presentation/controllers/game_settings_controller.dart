import 'dart:async';

import 'package:chess/chess_engine/chess_engine.dart';
import 'package:chess/features/game/domain/entities/board_theme.dart';
import 'package:chess/features/game/domain/entities/game_statistics.dart';
import 'package:chess/features/game/domain/repositories/game_repository.dart';
import 'package:get/get.dart';

/// Manages offline game preferences stored in Hive.
class GameSettingsController extends GetxController {
  GameSettingsController(this._repository);

  final GameRepository _repository;

  BoardTheme boardTheme = BoardTheme.classic;
  int defaultMinutes = 10;
  int defaultIncrement = 0;
  AiDifficulty defaultAiDifficulty = AiDifficulty.medium;
  bool hapticsEnabled = true;
  bool autoSaveEnabled = true;
  bool isLoading = true;


  Future<void> load() async {
    isLoading = true;
    update();
    boardTheme = await _repository.loadBoardTheme();
    defaultMinutes = await _repository.loadDefaultMinutes();
    defaultIncrement = await _repository.loadDefaultIncrement();
    defaultAiDifficulty = await _repository.loadDefaultAiDifficulty();
    hapticsEnabled = await _repository.loadHapticsEnabled();
    autoSaveEnabled = await _repository.loadAutoSaveEnabled();
    isLoading = false;
    update();
  }

  Future<void> setBoardTheme(BoardTheme theme) async {
    boardTheme = theme;
    await _repository.saveBoardTheme(theme);
    update();
  }

  Future<void> setDefaultMinutes(int minutes) async {
    defaultMinutes = minutes;
    await _repository.saveDefaultMinutes(minutes);
    update();
  }

  Future<void> setDefaultIncrement(int seconds) async {
    defaultIncrement = seconds;
    await _repository.saveDefaultIncrement(seconds);
    update();
  }

  Future<void> setDefaultAiDifficulty(AiDifficulty difficulty) async {
    defaultAiDifficulty = difficulty;
    await _repository.saveDefaultAiDifficulty(difficulty);
    update();
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    hapticsEnabled = enabled;
    await _repository.saveHapticsEnabled(enabled);
    update();
  }

  Future<void> setAutoSaveEnabled(bool enabled) async {
    autoSaveEnabled = enabled;
    await _repository.saveAutoSaveEnabled(enabled);
    update();
  }

  Future<void> resetStatistics() async {
    await _repository.saveStatistics(const GameStatistics());
    update();
  }
}
