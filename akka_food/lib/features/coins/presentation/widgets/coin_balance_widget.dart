import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../notifiers/coin_notifier.dart';

/// Displays the user's current coin balance alongside a coin icon.
///
/// Designed to be compact enough for use in an app bar or profile header.
/// Watches [coinBalanceStreamProvider] for real-time balance updates.
///
/// Satisfies:
/// - Requirement 3 AC1: Display current coin balance in app header/profile
/// - Requirement 3 AC2: Updates within 5 seconds via real-time stream
class CoinBalanceWidget extends ConsumerWidget {
  const CoinBalanceWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(coinBalanceStreamProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return balanceAsync.when(
      data: (balance) => _buildBalance(context, balance, colorScheme),
      loading: () => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => _buildBalance(context, 0, colorScheme),
    );
  }

  Widget _buildBalance(
    BuildContext context,
    int balance,
    ColorScheme colorScheme,
  ) {
    final formattedBalance = NumberFormat('#,###').format(balance);
    final theme = Theme.of(context);

    return Semantics(
      label: '$balance coins',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.monetization_on,
            color: Colors.amber[700],
            size: 20,
          ),
          const SizedBox(width: 4),
          Text(
            formattedBalance,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
