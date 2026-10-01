import 'dart:async';

import 'package:chess/app/widgets/responsive_content.dart';
import 'package:chess/features/online/domain/entities/matchmaking.dart';
import 'package:chess/features/online/presentation/controllers/matchmaking_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Matchmaking: quick match, create room, and join room.
class MatchmakingPage extends GetView<MatchmakingController> {
  const MatchmakingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Play Online'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Quick match'),
              Tab(text: 'Create'),
              Tab(text: 'Join'),
            ],
          ),
        ),
        body: GetBuilder<MatchmakingController>(
          builder: (c) => ResponsiveContent(
            child: TabBarView(
              children: [
                _QuickMatchTab(controller: c),
                _CreateRoomTab(controller: c),
                _JoinRoomTab(controller: c),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SharedOptions extends StatelessWidget {
  const _SharedOptions({required this.controller});

  final MatchmakingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Game type', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'casual', label: Text('Casual')),
            ButtonSegment(value: 'rated', label: Text('Rated')),
          ],
          selected: {c.mode},
          onSelectionChanged:
              c.isSearching ? null : (value) => c.setMode(value.first),
        ),
        const SizedBox(height: 24),
        Text('Time control', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final tc in MatchmakingController.timeControls)
              ChoiceChip(
                label: Text(tc),
                selected: c.timeControl == tc,
                onSelected:
                    c.isSearching ? null : (_) => c.setTimeControl(tc),
              ),
          ],
        ),
      ],
    );
  }
}

class _QuickMatchTab extends StatelessWidget {
  const _QuickMatchTab({required this.controller});

  final MatchmakingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = controller;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SharedOptions(controller: c),
          const SizedBox(height: 24),
          Text('Match type', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<MatchSearchType>(
            segments: const [
              ButtonSegment(
                value: MatchSearchType.rated,
                label: Text('Rating'),
                icon: Icon(Icons.leaderboard_outlined),
              ),
              ButtonSegment(
                value: MatchSearchType.random,
                label: Text('Random'),
                icon: Icon(Icons.shuffle),
              ),
            ],
            selected: {c.matchType},
            onSelectionChanged: c.isSearching
                ? null
                : (value) => c.setMatchType(value.first),
          ),
          const Spacer(),
          if (c.statusMessage != null) ...[
            if (c.isSearching)
              const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 16),
            Text(
              c.statusMessage!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
          ],
          if (c.isSearching)
            OutlinedButton(
              onPressed: () => unawaited(c.cancelSearch()),
              child: const Text('Cancel search'),
            )
          else
            FilledButton(
              onPressed: () => unawaited(c.startSearch()),
              child: const Text('Find opponent'),
            ),
        ],
      ),
    );
  }
}

class _CreateRoomTab extends StatelessWidget {
  const _CreateRoomTab({required this.controller});

  final MatchmakingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = controller;
    final invite = c.activeInvite;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SharedOptions(controller: c),
          const Spacer(),
          if (invite != null) ...[
            Text('Room code', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            SelectableText(
              invite.inviteCode,
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall?.copyWith(
                letterSpacing: 6,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Expires in ${_formatRemaining(invite.expiresAt)}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => unawaited(c.copyInviteCode()),
              icon: const Icon(Icons.copy),
              label: const Text('Copy code'),
            ),
            const SizedBox(height: 12),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 8),
            Text(
              c.statusMessage ?? 'Waiting for opponent to join…',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => unawaited(c.cancelSearch()),
              child: const Text('Cancel'),
            ),
          ] else ...[
            FilledButton(
              onPressed: c.isSearching ? null : () => unawaited(c.createRoom()),
              child: const Text('Create room'),
            ),
          ],
        ],
      ),
    );
  }

  String _formatRemaining(DateTime expiresAt) {
    final diff = expiresAt.difference(DateTime.now());
    if (diff.isNegative) return '0m';
    return '${diff.inMinutes}m ${diff.inSeconds % 60}s';
  }
}

class _JoinRoomTab extends StatelessWidget {
  const _JoinRoomTab({required this.controller});

  final MatchmakingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = controller;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Invite code', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            enabled: !c.isSearching,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: const InputDecoration(
              hintText: 'ABC123',
              border: OutlineInputBorder(),
            ),
            onChanged: c.setInviteCode,
          ),
          const Spacer(),
          if (c.statusMessage != null && c.isSearching) ...[
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 16),
            Text(c.statusMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
          ],
          FilledButton(
            onPressed: c.isSearching ? null : () => unawaited(c.joinRoom()),
            child: const Text('Join room'),
          ),
        ],
      ),
    );
  }
}
