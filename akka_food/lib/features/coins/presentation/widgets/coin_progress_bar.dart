import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifiers/coin_notifier.dart';

/// Displays a progress bar showing how close the user is to the next
/// 1000-coin redemption threshold.
///
/// Watches [coinBalanceProvider] for the computed [CoinBalance] which includes
/// [progress] (0.0–1.0) and [coinsToNext].
///
/// Satisfies:
/// - Requirement 3 AC3: Display a progress indicator showing how many more
///   coins are needed to reach the next 1000-coin redemption threshold.
class CoinProgressBar extends ConsumerWidget {
  const CoinProgressBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coinBalance = ref.watch(coinBalanceProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: '${coinBalance.coinsToNext} coins to next reward',
      value: '${(coinBalance.progress * 100).round()}%',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: coinBalance.progress,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${coinBalance.coinsToNext} coins to next reward',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
