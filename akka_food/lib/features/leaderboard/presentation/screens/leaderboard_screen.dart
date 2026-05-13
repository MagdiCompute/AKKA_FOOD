import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/animated_list_item.dart';
import '../../../../core/widgets/profile_avatar_button.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/leaderboard_period.dart';
import '../notifiers/leaderboard_notifier.dart';
import '../widgets/current_user_rank_card.dart';
import '../widgets/leaderboard_entry_tile.dart';

/// The main Leaderboard screen.
///
/// Displays:
/// - A tab bar with three period tabs: All-Time, Monthly, Weekly (Req 1 AC3).
/// - A scrollable list of the top 100 leaderboard entries ranked by score
///   descending (Req 1 AC1).
/// - Loading indicator while data is being fetched.
/// - Error state with retry option on failure.
///
/// Uses [leaderboardStreamProvider] for real-time Firestore updates.
/// Period switching triggers a new stream subscription automatically
/// (Req 1 AC4).
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  /// Maps tab indices to [LeaderboardPeriod] enum values.
  static const _periods = [
    LeaderboardPeriod.allTime,
    LeaderboardPeriod.monthly,
    LeaderboardPeriod.weekly,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _periods.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  /// Called when the user switches tabs. Forces a rebuild so the correct
  /// stream provider is watched.
  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  /// The currently selected [LeaderboardPeriod] based on the active tab.
  LeaderboardPeriod get _selectedPeriod => _periods[_tabController.index];

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
      bottomNavigationBar: CurrentUserRankCard(period: _selectedPeriod),
    );
  }

  // ---------------------------------------------------------------------------
  // AppBar with TabBar
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      leading: ProfileAvatarButton(
        onTap: () => context.push(AppRoutes.profile),
      ),
      title: const Text('Classement'),
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Tout le temps'),
          Tab(text: 'Ce mois'),
          Tab(text: 'Cette semaine'),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Body — watches the stream provider for the selected period
  // ---------------------------------------------------------------------------

  Widget _buildBody(BuildContext context) {
    final leaderboardAsync = ref.watch(
      leaderboardStreamProvider(_selectedPeriod),
    );

    return leaderboardAsync.when(
      data: (entries) => _buildLeaderboardList(context, entries),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildErrorState(context, error),
    );
  }

  // ---------------------------------------------------------------------------
  // Leaderboard list (Req 1 AC1 — top 100 entries ranked by score descending)
  // ---------------------------------------------------------------------------

  Widget _buildLeaderboardList(
    BuildContext context,
    List<LeaderboardEntry> entries,
  ) {
    if (entries.isEmpty) {
      return _buildEmptyState(context);
    }

    // Check if the current user is already in the top 100 list.
    final isCurrentUserInList = entries.any((e) => e.isCurrentUser);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: entries.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return AnimatedListItem(
                index: index,
                child: _buildEntryTile(context, entry),
              );
            },
          ),
        ),
        // Req 2 AC2: If the current user's rank is outside the top 100,
        // display their rank, score, and a separator below the top 100 list.
        if (!isCurrentUserInList)
          _OutsideTop100Section(period: _selectedPeriod),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Entry tile — uses LeaderboardEntryTile widget (Req 1 AC2)
  // ---------------------------------------------------------------------------

  Widget _buildEntryTile(BuildContext context, LeaderboardEntry entry) {
    return LeaderboardEntryTile(entry: entry);
  }

  // ---------------------------------------------------------------------------
  // Empty state — period-specific messaging for new periods with no data
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState(BuildContext context) {
    final heading = _emptyStateHeading(_selectedPeriod);
    final subtitle = _emptyStateSubtitle(_selectedPeriod);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.leaderboard_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              heading,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Returns the empty state heading based on the selected period.
  String _emptyStateHeading(LeaderboardPeriod period) {
    switch (period) {
      case LeaderboardPeriod.allTime:
        return 'Aucun classement pour le moment';
      case LeaderboardPeriod.monthly:
        return 'Aucun classement ce mois-ci';
      case LeaderboardPeriod.weekly:
        return 'Aucun classement cette semaine';
    }
  }

  /// Returns the empty state subtitle based on the selected period.
  String _emptyStateSubtitle(LeaderboardPeriod period) {
    switch (period) {
      case LeaderboardPeriod.allTime:
        return 'Soyez le premier à passer une commande !';
      case LeaderboardPeriod.monthly:
        return 'Un nouveau mois commence. Passez une commande pour mener le classement !';
      case LeaderboardPeriod.weekly:
        return 'Une nouvelle semaine commence. Passez une commande pour mener le classement !';
    }
  }

  // ---------------------------------------------------------------------------
  // Error state with retry
  // ---------------------------------------------------------------------------

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Échec du chargement du classement',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.invalidate(
                leaderboardStreamProvider(_selectedPeriod),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Outside Top 100 Section (Req 2 AC2)
// ---------------------------------------------------------------------------

/// Displays a visual separator and the current user's leaderboard entry
/// below the top 100 list when the user's rank is outside the top 100.
///
/// Satisfies Requirement 2 AC2: IF the current User's rank is outside the
/// top 100, THE Flutter app SHALL display the User's rank, score, and a
/// separator below the top 100 list.
class _OutsideTop100Section extends ConsumerWidget {
  const _OutsideTop100Section({required this.period});

  /// The current leaderboard period to fetch the user's entry for.
  final LeaderboardPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<LeaderboardEntry?>(
      future: ref
          .read(leaderboardNotifierProvider.notifier)
          .getCurrentUserEntry(period),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final entry = snapshot.data;
        if (entry == null) {
          return const SizedBox.shrink();
        }

        // Only show if the user's rank is actually > 100
        if (entry.rank <= 100) {
          return const SizedBox.shrink();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSeparator(context),
            LeaderboardEntryTile(entry: entry),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  /// Builds a visual separator indicating the user's position is below
  /// the top 100.
  Widget _buildSeparator(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: colorScheme.outlineVariant,
              thickness: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '• • •  Votre position  • • •',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: colorScheme.outlineVariant,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
}
