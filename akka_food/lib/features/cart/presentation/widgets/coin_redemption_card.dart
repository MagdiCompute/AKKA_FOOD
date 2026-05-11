import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akka_food/features/cart/presentation/notifiers/cart_notifier.dart';
import 'package:akka_food/features/user_profile/presentation/notifiers/coin_history_notifier.dart';

/// Displays a coin redemption toggle card on the Cart screen.
///
/// Visibility rules (Req 7.1, 7.6):
/// - Renders only when the authenticated user's coin balance is ≥ 1 000.
/// - Returns [SizedBox.shrink] when the balance is below 1 000 or while
///   the balance is loading / in error state.
///
/// When visible, the card shows:
/// - The user's current coin balance.
/// - The maximum redeemable amount in XOF (Req 7.2).
/// - A [Switch] that applies (Req 7.3) or removes (Req 7.5) the coin
///   redemption discount.
class CoinRedemptionCard extends ConsumerWidget {
  const CoinRedemptionCard({super.key});

  // ---------------------------------------------------------------------------
  // Max-redeemable calculation (mirrors CartNotifier._calculateMaxRedeemableCoins)
  // ---------------------------------------------------------------------------

  /// Returns the largest multiple of 1 000 that does not exceed [coinBalance]
  /// and does not exceed [subtotal] in XOF.
  ///
  /// Mirrors the private helper in [CartNotifier] so the card can display the
  /// redeemable amount without coupling to the notifier's internals.
  static int _maxRedeemable(int coinBalance, double subtotal) {
    final maxByBalance = (coinBalance ~/ 1000) * 1000;
    final maxBySubtotal = subtotal.floor();
    final maxRedeemable = min(maxByBalance, maxBySubtotal);
    return (maxRedeemable ~/ 1000) * 1000;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the real-time coin balance stream (Req 7.1, 7.6).
    final coinBalanceAsync = ref.watch(coinBalanceProvider);

    // While loading or on error, hide the card gracefully.
    final coinBalance = coinBalanceAsync.valueOrNull ?? 0;

    // Req 7.1 / 7.6 — only show when balance ≥ 1 000.
    if (coinBalance < 1000) return const SizedBox.shrink();

    final cart = ref.watch(cartNotifierProvider);
    final cartNotifier = ref.read(cartNotifierProvider.notifier);

    final redeemableAmount = _maxRedeemable(coinBalance, cart.subtotal);
    final isApplied = cart.redeemedCoins > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // ── Coin icon ────────────────────────────────────────────────
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.monetization_on,
                  color: Colors.amber.shade700,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              // ── Text column ──────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Redeem Coins',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'You have $coinBalance coins',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    if (redeemableAmount > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Save $redeemableAmount XOF',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.amber.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Toggle switch ────────────────────────────────────────────
              Switch(
                value: isApplied,
                onChanged: redeemableAmount > 0
                    ? (value) {
                        if (value) {
                          // Req 7.3 — apply coin redemption discount.
                          cartNotifier.applyCoins(coinBalance);
                        } else {
                          // Req 7.5 — remove coin redemption discount.
                          cartNotifier.removeCoins();
                        }
                      }
                    : null, // Disable toggle when nothing is redeemable.
              ),
            ],
          ),
        ),
      ),
    );
  }
}
