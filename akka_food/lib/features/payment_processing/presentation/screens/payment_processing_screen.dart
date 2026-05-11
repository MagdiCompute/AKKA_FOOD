import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../cart/domain/entities/cart.dart';
import '../notifiers/payment_notifier.dart';
import 'order_confirmation_screen.dart';

// ---------------------------------------------------------------------------
// PaymentProcessingScreen
// ---------------------------------------------------------------------------

/// Displays an animated loading indicator, status message, and cancel button
/// while the payment is being processed via Orange Money.
///
/// Watches [paymentNotifierProvider] for state transitions:
/// - [PaymentUIState.success] → navigates to OrderConfirmationScreen
/// - [PaymentUIState.failed] → navigates to PaymentFailureScreen
/// - [PaymentUIState.cancelled] → navigates back to cart
///
/// Prevents back navigation — user must explicitly cancel via the cancel button.
///
/// Satisfies:
/// - Req 1 AC2: Display Orange Money payment confirmation screen to User
/// - Req 4 AC1: Cancel pending payment before confirmation
/// - Req 4 AC2: Return User to Cart screen with items intact on cancellation
class PaymentProcessingScreen extends ConsumerStatefulWidget {
  const PaymentProcessingScreen({super.key});

  @override
  ConsumerState<PaymentProcessingScreen> createState() =>
      _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState
    extends ConsumerState<PaymentProcessingScreen>
    with SingleTickerProviderStateMixin {
  /// Whether we've already navigated away to prevent duplicate navigation.
  bool _hasNavigated = false;

  /// Remaining time display timer.
  Timer? _countdownTimer;

  /// Remaining seconds until client-side timeout (5 minutes = 300 seconds).
  int _remainingSeconds = 300;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _startCountdown();

    // Pulse animation for the phone icon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  /// Starts a 1-second interval countdown timer for the remaining time display.
  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  /// Formats remaining seconds as "M:SS".
  String _formatRemainingTime() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // ---------------------------------------------------------------------------
  // Cancel payment
  // ---------------------------------------------------------------------------

  /// Shows a confirmation dialog before cancelling the payment.
  Future<void> _onCancelTapped() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Payment?'),
        content: const Text(
          'Are you sure you want to cancel this payment? '
          'You will be returned to your cart.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No, Wait'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final transactionId =
          ref.read(paymentNotifierProvider.notifier).currentTransactionId;
      if (transactionId != null) {
        await ref
            .read(paymentNotifierProvider.notifier)
            .cancelPayment(transactionId);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Navigation based on state
  // ---------------------------------------------------------------------------

  /// Handles navigation when the payment state reaches a terminal state.
  void _handleStateTransition(PaymentUIState state) {
    if (_hasNavigated) return;

    switch (state) {
      case PaymentUIState.success:
        _hasNavigated = true;
        // Build confirmation data from the cart and transaction.
        final cart = GoRouterState.of(context).extra as Cart?;
        final transactionId = ref
            .read(paymentNotifierProvider.notifier)
            .currentTransactionId;
        final confirmationData = OrderConfirmationData(
          orderId: transactionId ?? 'unknown',
          items: cart?.items ?? [],
          totalPaid: cart?.total ?? 0,
        );
        // Navigate to order confirmation screen (replace current route)
        context.go(
          AppRoutes.paymentConfirmation,
          extra: confirmationData,
        );
      case PaymentUIState.failed:
        _hasNavigated = true;
        // Navigate to payment failure screen (replace current route)
        context.go(AppRoutes.paymentFailure);
      case PaymentUIState.cancelled:
        _hasNavigated = true;
        // Return to cart with items intact (Req 4 AC2)
        context.go(AppRoutes.cart);
      case PaymentUIState.idle:
      case PaymentUIState.initiating:
      case PaymentUIState.processing:
        // No navigation needed — stay on this screen.
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Listen for terminal state transitions to navigate.
    ref.listen<AsyncValue<PaymentUIState>>(
      paymentNotifierProvider,
      (previous, next) {
        final state = next.valueOrNull;
        if (state != null) {
          _handleStateTransition(state);
        }
      },
    );

    final theme = Theme.of(context);

    // Prevent back navigation — user must explicitly cancel.
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // ── Animated loading indicator ─────────────────────────────
                _buildLoadingIndicator(theme),

                const SizedBox(height: 32),

                // ── Status message ─────────────────────────────────────────
                _buildStatusMessage(theme),

                const SizedBox(height: 16),

                // ── Timer display ──────────────────────────────────────────
                _buildTimerDisplay(theme),

                const Spacer(flex: 3),

                // ── Cancel button ──────────────────────────────────────────
                _buildCancelButton(theme),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI Components
  // ---------------------------------------------------------------------------

  /// Animated loading indicator with a pulsing phone icon and circular progress.
  Widget _buildLoadingIndicator(ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Circular progress indicator
              const SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  color: Colors.orange,
                ),
              ),
              // Pulsing phone icon
              ScaleTransition(
                scale: _pulseAnimation,
                child: Icon(
                  Icons.phone_android,
                  size: 48,
                  color: theme.colorScheme.primary,
                  semanticLabel: 'Waiting for phone confirmation',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Status message telling the user what's happening.
  Widget _buildStatusMessage(ThemeData theme) {
    return Column(
      children: [
        Text(
          'Processing your payment...',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          semanticsLabel: 'Processing your payment',
        ),
        const SizedBox(height: 12),
        Text(
          'Please confirm the payment on your phone.\n'
          'Orange Money will send a USSD push to your device.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Displays the remaining time before timeout.
  Widget _buildTimerDisplay(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 18,
            color: _remainingSeconds < 60
                ? Colors.red
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            'Time remaining: ${_formatRemainingTime()}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: _remainingSeconds < 60
                  ? Colors.red
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Cancel button with confirmation dialog.
  Widget _buildCancelButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: _onCancelTapped,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
        ),
        child: const Text(
          'Cancel Payment',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
