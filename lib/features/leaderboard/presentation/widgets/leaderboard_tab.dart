import 'dart:async';

import 'package:chess/core/firebase/firebase_bootstrap.dart';
import 'package:chess/features/leaderboard/domain/entities/leaderboard_entry.dart';
import 'package:chess/features/leaderboard/presentation/controllers/leaderboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Leaderboard tab with scope, sort, search, and pagination.
class LeaderboardTab extends GetView<LeaderboardController> {
  const LeaderboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    if (!FirebaseBootstrap.isInitialized) {
      return const Center(child: Text('Leaderboards require Firebase.'));
    }

    return const _LeaderboardTabBody();
  }
}

class _LeaderboardTabBody extends StatefulWidget {
  const _LeaderboardTabBody();

  @override
  State<_LeaderboardTabBody> createState() => _LeaderboardTabBodyState();
}

class _LeaderboardTabBodyState extends State<_LeaderboardTabBody> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  LeaderboardController get controller => Get.find<LeaderboardController>();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      unawaited(controller.loadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LeaderboardController>(
      builder: (c) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Leaderboard',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 16),
            SegmentedButton<LeaderboardScope>(
              segments: const [
                ButtonSegment(
                  value: LeaderboardScope.global,
                  label: Text('Global'),
                ),
                ButtonSegment(
                  value: LeaderboardScope.weekly,
                  label: Text('Weekly'),
                ),
                ButtonSegment(
                  value: LeaderboardScope.monthly,
                  label: Text('Monthly'),
                ),
              ],
              selected: {c.scope},
              onSelectionChanged: (value) =>
                  unawaited(c.setScope(value.first)),
            ),
            const SizedBox(height: 12),
            SegmentedButton<LeaderboardMetric>(
              segments: const [
                ButtonSegment(
                  value: LeaderboardMetric.rating,
                  label: Text('Rating'),
                ),
                ButtonSegment(
                  value: LeaderboardMetric.wins,
                  label: Text('Wins'),
                ),
              ],
              selected: {c.metric},
              onSelectionChanged: (value) =>
                  unawaited(c.setMetric(value.first)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search players…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          unawaited(c.search(''));
                          setState(() {});
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: c.search,
            ),
            const SizedBox(height: 8),
            Text(
              '${c.scopeLabel} · ${c.metricLabel}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildBody(context, c)),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, LeaderboardController c) {
    if (!c.isAvailable) {
      return const Center(child: Text('Leaderboards require Firebase.'));
    }

    if (c.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (c.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(c.errorMessage!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => unawaited(c.reload()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (c.entries.isEmpty) {
      return const Center(child: Text('No players found'));
    }

    return RefreshIndicator(
      onRefresh: c.reload,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: c.entries.length + (c.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= c.entries.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final entry = c.entries[index];
          return _LeaderboardTile(
            entry: entry,
            metric: c.metric,
            highlighted: c.isCurrentUser(entry.uid),
          );
        },
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({
    required this.entry,
    required this.metric,
    required this.highlighted,
  });

  final LeaderboardEntry entry;
  final LeaderboardMetric metric;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = metric == LeaderboardMetric.rating
        ? '${entry.rating}'
        : '${entry.wins}';

    return Card(
      color: highlighted ? theme.colorScheme.primaryContainer : null,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              entry.photoUrl != null ? NetworkImage(entry.photoUrl!) : null,
          child: entry.photoUrl == null
              ? Text(entry.displayName.characters.first.toUpperCase())
              : null,
        ),
        title: Text(
          entry.displayName,
          style: highlighted
              ? TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                )
              : null,
        ),
        subtitle: Text('${entry.played} games played'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('#${entry.rank}', style: theme.textTheme.labelSmall),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
