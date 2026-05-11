import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../notifiers/payment_notifier.dart';

// ---------------------------------------------------------------------------
// OrderConfirmationData
// ---------------------------------------------------------------------------

/// Data class holding the information displayed on the Order Confirmation screen.
///
/// Passed via GoRouter's `extra` parameter from the PaymentProcessingScreen
/// after a successful payment.
class OrderConfirmationData {
  const OrderConfirmationData({
    required this.orderId,
    required this.items,
    required this.totalPaid,
  });

  /// The unique order ID (full Firestore document ID).
  final String orderId;

  /// The list of items that were ordered.
  final List<CartItem> items;

  /// The total amount paid in XOF.
  final double totalPaid;
}

// ---------------------------------------------------------------------------
// OrderConfirmationScreen
// ---------------------------------------------------------------------------

/// Displays a celebratory order confirmation after a successful payment.
///
/// Shows:
/// - Success indicator (checkmark icon)
/// - Celebratory message "Order Confirmed! 🎉"
/// - Order ID (first 8 characters for readability)
/// - Items list summary
/// - Total paid in XOF format
/// - Coins earned (5% of total)
/// - Estimated delivery time (static estimate)
/// - "Track Order" button → delivery tracking screen
/// - "Back to Home" button → main screen
///
/// Resets the [PaymentNotifier] when leaving this screen.
///
/// Satisfies:
/// - Req 2 AC5: Navigate to Order Confirmation screen displaying Order ID,
///   items, total paid, and estimated delivery time
class OrderConfirmationScreen extends ConsumerStatefulWidget {
  const OrderConfirmationScreen({super.key});

  @override
  ConsumerState<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState
    extends ConsumerState<OrderConfirmationScreen> {
  @override
  void dispose() {
    super.dispose();
  }

  /// Resets the payment notifier and navigates to the home screen.
  void _onBackToHome() {
    ref.read(paymentNotifierProvider.notifier).reset();
    context.go(AppRoutes.home);
  }

  /// Resets the payment notifier and navigates to the delivery tracking screen.
  void _onTrackOrder(String orderId) {
    ref.read(paymentNotifierProvider.notifier).reset();
    // Navigate to order detail/tracking screen
    context.go('/profile/orders/$orderId');
  }

  /// Formats an amount in XOF with thousands separator.
  /// e.g. 2500.0 → "2,500 XOF"
  String _formatXOF(double amount) {
    final intAmount = amount.round();
    final formatted = intAmount.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
    return '$formatted XOF';
  }

  /// Calculates coins earned (5% of total, rounded down).
  int _calculateCoinsEarned(double totalAmount) =>
      (totalAmount * 0.05).floor();

  /// Returns the first 8 characters of the order ID for readability.
  String _shortOrderId(String orderId) {
    if (orderId.length <= 8) return orderId;
    return orderId.substring(0, 8).toUpperCase();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final data = GoRouterState.of(context).extra as OrderConfirmationData?;

    // Fallback if no data is passed (e.g. deep link or direct navigation)
    if (data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Confirmation')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              const Text('Your order has been confirmed!'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _onBackToHome,
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      );
    }

    final coinsEarned = _calculateCoinsEarned(data.totalPaid);
    final theme = Theme.of(context);

    // Prevent back navigation — user should use the buttons provided.
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      // ── Success indicator ──────────────────────────────────
                      _buildSuccessIndicator(theme),

                      const SizedBox(height: 24),

                      // ── Celebratory message ────────────────────────────────
                      _buildCelebratoryMessage(theme),

                      const SizedBox(height: 32),

                      // ── Order details card ─────────────────────────────────
                      _buildOrderDetailsCard(theme, data),

                      const SizedBox(height: 16),

                      // ── Coins earned card ──────────────────────────────────
                      _buildCoinsEarnedCard(theme, coinsEarned),

                      const SizedBox(height: 16),

                      // ── ETA card ───────────────────────────────────────────
                      _buildETACard(theme),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // ── Action buttons ───────────────────────────────────────────
              _buildActionButtons(theme, data.orderId),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI Components
  // ---------------------------------------------------------------------------

  /// Green checkmark icon indicating payment success.
  Widget _buildSuccessIndicator(ThemeData theme) {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check,
        size: 48,
        color: Colors.white,
        semanticLabel: 'Payment successful',
      ),
    );
  }

  /// Celebratory heading message.
  Widget _buildCelebratoryMessage(ThemeData theme) {
    return Column(
      children: [
        Text(
          'Order Confirmed! 🎉',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          semanticsLabel: 'Order Confirmed',
        ),
        const SizedBox(height: 8),
        Text(
          'Your payment was successful and your order is being prepared.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Card displaying order ID, items list, and total paid.
  Widget _buildOrderDetailsCard(ThemeData theme, OrderConfirmationData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Order #${_shortOrderId(data.orderId)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  semanticsLabel:
                      'Order number ${_shortOrderId(data.orderId)}',
                ),
              ],
            ),

            const Divider(height: 24),

            // Items list
            Text(
              'Items',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            ...data.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.mealName,
                        style: theme.textTheme.bodyMedium,
                        semanticsLabel:
                            '${item.mealName}, quantity ${item.quantity}',
                      ),
                    ),
                    Text(
                      '×${item.quantity}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatXOF(item.lineTotal),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 24),

            // Total paid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Paid',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatXOF(data.totalPaid),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  semanticsLabel: 'Total paid ${_formatXOF(data.totalPaid)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Card displaying coins earned from this purchase.
  Widget _buildCoinsEarnedCard(ThemeData theme, int coinsEarned) {
    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
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
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coins Earned',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.amber.shade800,
                    ),
                  ),
                  Text(
                    '+$coinsEarned coins',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                    semanticsLabel: '$coinsEarned coins earned',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Card displaying estimated delivery time.
  Widget _buildETACard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.delivery_dining,
              size: 28,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimated Delivery',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '30-45 minutes',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    semanticsLabel: 'Estimated delivery time 30 to 45 minutes',
                  ),
                ],
              ),
            ),
            Icon(
              Icons.timer_outlined,
              size: 20,
              color: theme.colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }

  /// Track Order and Back to Home buttons.
  Widget _buildActionButtons(ThemeData theme, String orderId) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: [
          // Track Order button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: () => _onTrackOrder(orderId),
              icon: const Icon(Icons.local_shipping_outlined),
              label: const Text(
                'Track Order',
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
          // Back to Home button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: _onBackToHome,
              child: const Text(
                'Back to Home',
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
}
