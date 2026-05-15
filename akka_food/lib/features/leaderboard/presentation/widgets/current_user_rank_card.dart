import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/avatar_bank.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/leaderboard_period.dart';
import '../notifiers/leaderboard_notifier.dart';

/// A sticky card that displays the current user's rank and score.
///
/// Always visible at the bottom of the Leaderboard screen regardless of
/// scroll position.
///
/// Satisfies Requirement 2 AC3: THE Flutter app SHALL display the current
/// User's rank and score in a sticky card at the bottom of the Leaderboard
/// screen regardless of scroll position.
///
/// States:
/// - Loading: shows a shimmer placeholder while fetching data.
/// - Data: shows "Your rank: #X | Score: Y orders".
/// - Null/Error: hides the card entirely (user not signed in or no data).
class CurrentUserRankCard extends ConsumerWidget {
  const CurrentUserRankCard({
    super.key,
    required this.period,
  });

  /// The current leaderboard period to fetch the user's rank for.
  final LeaderboardPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<LeaderboardEntry?>(
      future: ref
          .read(leaderboardNotifierProvider.notifier)
          .getCurrentUserEntry(period),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState(context);
        }

        final entry = snapshot.data;
        if (entry == null) {
          return const SizedBox.shrink();
        }

        return _buildCard(context, entry);
      },
    );
  }

  /// Builds the main card displaying rank and score.
  Widget _buildCard(BuildContext context, LeaderboardEntry entry) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // User's avatar
          AvatarBankDisplay(
            avatarUrl: entry.avatarUrl,
            radius: 22,
            displayName: entry.displayName,
          ),
          const SizedBox(width: 16),
          // Label and score
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Votre classement',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rang #${entry.rank} | ${entry.score} commandes',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          // Score badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${entry.score} cmd',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a loading placeholder with shimmer-like appearance.
  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      height: 72,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Placeholder circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(width: 16),
          // Placeholder text lines
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 140,
                  height: 14,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ],
            ),
          ),
          // Placeholder badge
          Container(
            width: 70,
            height: 28,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ),
    );
  }
}
