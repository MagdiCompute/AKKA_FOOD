import 'package:flutter/material.dart';

import 'package:akka_food/core/widgets/avatar_bank.dart';
import '../../domain/entities/leaderboard_entry.dart';

/// A tile displaying a single leaderboard entry row.
///
/// Shows:
/// - Rank indicator (medal emoji for top 3, number for rank 4+)
/// - Circular avatar (network image or initials placeholder)
/// - Display name (single line, ellipsis overflow)
/// - Score as "X orders" text
///
/// Satisfies Requirement 1 AC2: Each LeaderboardEntry SHALL display rank,
/// display name, avatar (or placeholder), and score (total orders).
class LeaderboardEntryTile extends StatelessWidget {
  const LeaderboardEntryTile({
    super.key,
    required this.entry,
  });

  /// The leaderboard entry data to display.
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: entry.isCurrentUser
            ? Border.all(color: colorScheme.primary, width: 1.5)
            : Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Rank indicator
          _buildRankIndicator(context),
          const SizedBox(width: 12),
          // Avatar
          _buildAvatar(context),
          const SizedBox(width: 12),
          // Display name
          Expanded(
            child: Text(
              entry.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight:
                    entry.isCurrentUser ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Score
          _buildScore(context),
        ],
      ),
    );
  }

  /// Builds the rank indicator widget.
  ///
  /// Top 3 ranks display medal emojis (🥇, 🥈, 🥉).
  /// Rank 4+ displays the number in a circular container.
  Widget _buildRankIndicator(BuildContext context) {
    final theme = Theme.of(context);

    if (entry.rank <= 3) {
      return SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: Text(
            _medalEmoji(entry.rank),
            style: const TextStyle(fontSize: 24),
            semanticsLabel: _rankSemanticsLabel(entry.rank),
          ),
        ),
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      alignment: Alignment.center,
      child: Text(
        '${entry.rank}',
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  /// Returns the medal emoji for ranks 1–3.
  String _medalEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }

  /// Returns an accessibility label for the rank.
  String _rankSemanticsLabel(int rank) {
    switch (rank) {
      case 1:
        return 'Médaille d\'or, rang 1';
      case 2:
        return 'Médaille d\'argent, rang 2';
      case 3:
        return 'Médaille de bronze, rang 3';
      default:
        return 'Rang $rank';
    }
  }

  /// Builds the circular avatar using the avatar bank system.
  Widget _buildAvatar(BuildContext context) {
    return AvatarBankDisplay(
      avatarUrl: entry.avatarUrl,
      radius: 20,
      displayName: entry.displayName,
    );
  }

  /// Builds the score display on the right side.
  Widget _buildScore(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Text(
      '${entry.score} commandes',
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.primary,
      ),
    );
  }
}
