import 'dart:async';

import 'package:chess/core/firebase/firebase_bootstrap.dart';
import 'package:chess/core/firebase/functions_service.dart';
import 'package:chess/core/utils/app_logger.dart';
import 'package:chess/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:chess/features/leaderboard/data/datasources/leaderboard_remote_datasource.dart';
import 'package:chess/features/leaderboard/data/repositories/leaderboard_repository_impl.dart';
import 'package:chess/features/leaderboard/domain/entities/leaderboard_entry.dart';
import 'package:chess/features/leaderboard/domain/repositories/leaderboard_repository.dart';
import 'package:get/get.dart';

/// Leaderboard tab state: scope, sort, search, and infinite scroll.
class LeaderboardController extends GetxController {
  LeaderboardController([LeaderboardRepository? repository])
      : _repository = repository;

  final LeaderboardRepository? _repository;

  LeaderboardScope scope = LeaderboardScope.global;
  LeaderboardMetric metric = LeaderboardMetric.rating;
  String searchQuery = '';

  final List<LeaderboardEntry> entries = [];
  LeaderboardCursor? _nextCursor;
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = false;
  String? errorMessage;
  bool isAvailable = false;

  static const pageSize = 25;

  @override
  void onInit() {
    super.onInit();
    isAvailable = FirebaseBootstrap.isInitialized && _repository != null;
    if (isAvailable) {
      unawaited(reload());
    }
  }

  Future<void> reload() async {
    if (!isAvailable) return;

    isLoading = true;
    errorMessage = null;
    entries.clear();
    _nextCursor = null;
    hasMore = false;
    update();

    try {
      final page = await _repository!.fetchPage(
        scope: scope,
        metric: metric,
        searchQuery: searchQuery.isEmpty ? null : searchQuery,
      );
      entries.addAll(page.entries);
      _nextCursor = page.nextCursor;
      hasMore = page.hasMore;
    } on Exception catch (error) {
      AppLogger.instance.e('Leaderboard load failed', error: error);
      errorMessage = 'Could not load leaderboard';
    } finally {
      isLoading = false;
      update();
    }
  }

  Future<void> loadMore() async {
    if (!isAvailable || isLoadingMore || !hasMore || _nextCursor == null) {
      return;
    }

    isLoadingMore = true;
    update();

    try {
      final page = await _repository!.fetchPage(
        scope: scope,
        metric: metric,
        cursor: _nextCursor,
        searchQuery: searchQuery.isEmpty ? null : searchQuery,
      );
      entries.addAll(page.entries);
      _nextCursor = page.nextCursor;
      hasMore = page.hasMore;
    } on Exception catch (error) {
      AppLogger.instance.w('Leaderboard pagination failed', error: error);
    } finally {
      isLoadingMore = false;
      update();
    }
  }

  Future<void> setScope(LeaderboardScope value) async {
    if (scope == value) return;
    scope = value;
    await reload();
  }

  Future<void> setMetric(LeaderboardMetric value) async {
    if (metric == value) return;
    metric = value;
    await reload();
  }

  Future<void> search(String query) async {
    final trimmed = query.trim();
    searchQuery = trimmed.length > 32 ? trimmed.substring(0, 32) : trimmed;
    await reload();
  }

  String? get currentUid =>
      Get.isRegistered<AuthSessionController>()
          ? Get.find<AuthSessionController>().user.value?.uid
          : null;

  bool isCurrentUser(String uid) => currentUid == uid;

  String get scopeLabel => switch (scope) {
        LeaderboardScope.global => 'Global',
        LeaderboardScope.weekly => 'This week',
        LeaderboardScope.monthly => 'This month',
      };

  String get metricLabel => switch (metric) {
        LeaderboardMetric.rating => 'Highest rating',
        LeaderboardMetric.wins => 'Most wins',
      };
}

/// Registers leaderboard dependencies.
class LeaderboardBinding {
  static void register() {
    if (!FirebaseBootstrap.isInitialized ||
        !Get.isRegistered<FunctionsService>() ||
        Get.isRegistered<LeaderboardRepository>()) {
      return;
    }

    Get.put<LeaderboardRepository>(
      LeaderboardRepositoryImpl(
        LeaderboardRemoteDataSource(Get.find<FunctionsService>()),
      ),
      permanent: true,
    );
  }
}
