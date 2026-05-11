import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../notifiers/payment_notifier.dart';

// ---------------------------------------------------------------------------
// PaymentFailureScreen
// ---------------------------------------------------------------------------

/// Displays a payment failure message with options to retry or cancel.
///
/// Shows:
/// - Red X failure indicator
/// - Failure reason text (passed via route `extra` or a default message)
/// - "Retry" button — resets the notifier and navigates to CheckoutScreen
///   to create a new transaction (Req 3 AC3)
/// - "Cancel" button — resets the notifier and returns to cart with items
///   intact (Req 3 AC4)
///
/// Resets the [PaymentNotifier] when leaving this screen.
///
/// Satisfies:
/// - Req 3 AC2: Display error screen with failure reason and options to
///   retry or cancel
/// - Req 3 AC3: Retry creates new Transaction with new reference
/// - Req 3 AC4: Cart contents retained on failure
class PaymentFailureScreen extends ConsumerWidget {
  const PaymentFailureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Failure reason can be passed via GoRouter's `extra` parameter.
    final failureReason =
        GoRouterState.of(context).extra as String? ?? 'Payment failed';

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Failure indicator ────────────────────────────────
                      _buildFailureIndicator(theme),

                      const SizedBox(height: 24),

                      // ── Failure heading ──────────────────────────────────
                      _buildFailureHeading(theme),

                      const SizedBox(height: 12),

                      // ── Failure reason ───────────────────────────────────
                      _buildFailureReason(theme, failureReason),
                    ],
                  ),
                ),
              ),

              // ── Action buttons ───────────────────────────────────────────
              _buildActionButtons(context, ref, theme),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI Components
  // ---------------------------------------------------------------------------

  /// Red X icon indicating payment failure.
  Widget _buildFailureIndicator(ThemeData theme) {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.close,
        size: 48,
        color: Colors.white,
        semanticLabel: 'Payment failed',
      ),
    );
  }

  /// Heading text for the failure screen.
  Widget _buildFailureHeading(ThemeData theme) {
    return Text(
      'Payment Failed',
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
      semanticsLabel: 'Payment Failed',
    );
  }

  /// Displays the failure reason text.
  Widget _buildFailureReason(ThemeData theme, String reason) {
    return Text(
      reason,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Retry and Cancel action buttons.
  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: [
          // Retry button — navigates to CheckoutScreen for a new transaction
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: () => _onRetry(context, ref),
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Retry',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Cancel button — returns to cart with items intact
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () => _onCancel(context, ref),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Resets the payment notifier and navigates back to CheckoutScreen.
  ///
  /// A new transaction will be created when the user initiates payment again
  /// (Req 3 AC3).
  void _onRetry(BuildContext context, WidgetRef ref) {
    ref.read(paymentNotifierProvider.notifier).reset();
    context.go(AppRoutes.payment);
  }

  /// Resets the payment notifier and returns to the cart screen.
  ///
  /// Cart contents are retained (Req 3 AC4).
  void _onCancel(BuildContext context, WidgetRef ref) {
    ref.read(paymentNotifierProvider.notifier).reset();
    context.go(AppRoutes.cart);
  }
}
