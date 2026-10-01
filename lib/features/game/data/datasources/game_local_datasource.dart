import 'dart:convert';

import 'package:chess/core/constants/app_constants.dart';
import 'package:chess/features/game/domain/entities/cloud_game_settings.dart';
import 'package:chess/features/game/domain/entities/game_history_entry.dart';
import 'package:chess/features/game/domain/entities/game_statistics.dart';
import 'package:chess/features/game/domain/entities/saved_game.dart';
import 'package:chess/features/game/domain/entities/sync_queue_entry.dart';
import 'package:hive/hive.dart';

/// Hive-backed local game storage and sync queue.
class GameLocalDataSource {
  Box<dynamic>? _boxCache;

  Future<Box<dynamic>> _box() async {
    if (_boxCache != null && _boxCache!.isOpen) return _boxCache!;
    _boxCache = await Hive.openBox(AppConstants.gameBoxName);
    return _boxCache!;
  }

  Future<SavedGame?> readSavedGame() async {
    final box = await _box();
    final raw = box.get(AppConstants.savedGameKey);
    if (raw is! String) return null;
    return SavedGame.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> writeSavedGame(SavedGame game) async {
    final box = await _box();
    await box.put(AppConstants.savedGameKey, jsonEncode(game.toJson()));
  }

  Future<void> deleteSavedGame() async {
    final box = await _box();
    await box.delete(AppConstants.savedGameKey);
  }

  Future<GameStatistics> readStatistics() async {
    final box = await _box();
    final raw = box.get(AppConstants.gameStatsKey);
    if (raw is! String) return const GameStatistics();
    return GameStatistics.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> writeStatistics(GameStatistics stats) async {
    final box = await _box();
    await box.put(AppConstants.gameStatsKey, jsonEncode(stats.toJson()));
  }

  Future<List<GameHistoryEntry>> readHistory() async {
    final box = await _box();
    final raw = box.get(AppConstants.gameHistoryKey);
    if (raw is! String) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => GameHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> writeHistory(List<GameHistoryEntry> entries) async {
    final box = await _box();
    await box.put(
      AppConstants.gameHistoryKey,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> appendHistory(GameHistoryEntry entry) async {
    final history = await readHistory();
    history.insert(0, entry);
    final trimmed = history.take(50).toList();
    await writeHistory(trimmed);
  }

  Future<CloudGameSettings?> readCloudSettingsCache() async {
    final box = await _box();
    final raw = box.get(AppConstants.cloudSettingsCacheKey);
    if (raw is! String) return null;
    return CloudGameSettings.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<void> writeCloudSettingsCache(CloudGameSettings settings) async {
    final box = await _box();
    await box.put(
      AppConstants.cloudSettingsCacheKey,
      jsonEncode(settings.toJson()),
    );
  }

  Future<List<SyncQueueEntry>> readSyncQueue() async {
    final box = await _box();
    final raw = box.get(AppConstants.syncQueueKey);
    if (raw is! String) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => SyncQueueEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> writeSyncQueue(List<SyncQueueEntry> queue) async {
    final box = await _box();
    await box.put(
      AppConstants.syncQueueKey,
      jsonEncode(queue.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> enqueue(SyncQueueEntry entry) async {
    final queue = await readSyncQueue();
    queue.removeWhere((e) => e.id == entry.id && e.type == entry.type);
    queue.add(entry);
    await writeSyncQueue(queue);
  }

  Future<String?> readString(String key) async {
    final box = await _box();
    return box.get(key) as String?;
  }

  Future<void> writeString(String key, String value) async {
    final box = await _box();
    await box.put(key, value);
  }

  Future<bool> readBool(String key, {bool defaultValue = true}) async {
    final box = await _box();
    return box.get(key, defaultValue: defaultValue) as bool;
  }

  Future<void> writeBool(String key, bool value) async {
    final box = await _box();
    await box.put(key, value);
  }

  Future<int> readInt(String key, {int defaultValue = 0}) async {
    final box = await _box();
    return box.get(key, defaultValue: defaultValue) as int;
  }

  Future<void> writeInt(String key, int value) async {
    final box = await _box();
    await box.put(key, value);
  }

  Future<int?> readLastSyncMillis() async {
    final box = await _box();
    return box.get(AppConstants.lastCloudSyncKey) as int?;
  }

  Future<void> writeLastSyncMillis(int millis) async {
    final box = await _box();
    await box.put(AppConstants.lastCloudSyncKey, millis);
  }
}
