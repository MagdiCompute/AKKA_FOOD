import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifiers/coin_notifier.dart';
import 'coin_earned_snackbar.dart';

/// A widget that listens for coin balance increases and shows a notification.
///
/// Place this widget in the widget tree (e.g., wrapping the main content area)
/// to automatically detect when the user's coin balance increases and display
/// a celebratory snackbar.
///
/// The listener compares the previous balance with the new balance emitted by
/// [coinBalanceStreamProvider]. When the new balance is higher, it calculates
/// the difference and shows [showCoinEarnedSnackbar].
///
/// Satisfies:
/// - Requirement 1 AC4: WHEN coins are credited, THE Flutter app SHALL display
///   a notification informing the User of the coins earned.
class CoinEarnedListener extends ConsumerStatefulWidget {
  /// Creates a [CoinEarnedListener].
  ///
  /// The [child] widget is rendered below this listener in the widget tree.
  const CoinEarnedListener({
    required this.child,
    super.key,
  });

  /// The widget below this listener in the tree.
  final Widget child;

  @override
  ConsumerState<CoinEarnedListener> createState() =>
      _CoinEarnedListenerState();
}

class _CoinEarnedListenerState extends ConsumerState<CoinEarnedListener> {
  /// The last known coin balance. Used to detect increases.
  ///
  /// Starts as `null` to avoid showing a notification on the initial load.
  int? _previousBalance;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<int>>(
      coinBalanceStreamProvider,
      (previous, next) {
        final newBalance = next.valueOrNull;
        if (newBalance == null) return;

        final oldBalance = _previousBalance;
        _previousBalance = newBalance;

        // Skip the initial load — no notification on first value
        if (oldBalance == null) return;

        // Only notify when balance increases (coins earned)
        if (newBalance > oldBalance) {
          final coinsEarned = newBalance - oldBalance;
          showCoinEarnedSnackbar(context, coinsEarned: coinsEarned);
        }
      },
    );

    return widget.child;
  }
}
