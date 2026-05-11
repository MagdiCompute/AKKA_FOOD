import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/delivery_status.dart';
import '../../domain/entities/order.dart';
import '../notifiers/delivery_tracking_notifier.dart';
import '../widgets/delivery_status_timeline.dart';
import '../widgets/eta_card.dart';

/// Screen that displays real-time order tracking information.
///
/// Accepts an [orderId] parameter (from route) and subscribes to
/// [deliveryTrackingNotifierProvider] for real-time Firestore updates.
///
/// Displays:
/// - A loading indicator while the order is being fetched.
/// - An error message with retry when the stream errors.
/// - The tracking UI with:
///   - [DeliveryStatusTimeline] placeholder (task 6.2)
///   - [ETACard] placeholder (task 6.3)
///   - Delivery confirmation + "Rate Order" button when delivered (task 6.4)
///
/// Satisfies Requirement 2 AC1, AC2, AC3, AC4, AC5.
class OrderTrackingScreen extends ConsumerStatefulWidget {
  /// The ID of the order to track.
  final String orderId;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  @override
  void initState() {
    super.initState();
    // Start watching the order for real-time updates (Req 2 AC1, AC2).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(deliveryTrackingNotifierProvider.notifier)
          .watchOrder(widget.orderId);
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(deliveryTrackingNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Tracking'),
      ),
      body: orderAsync.when(
        loading: _buildLoading,
        error: (error, _) {
          // If we have previously received data, show the last known order
          // with a non-blocking "Reconnecting..." banner instead of a full
          // error screen (Design doc: Error Handling).
          final lastKnown = ref
              .read(deliveryTrackingNotifierProvider.notifier)
              .lastKnownOrder;
          if (lastKnown != null) {
            return _buildReconnectingContent(context, lastKnown);
          }
          return _buildError(context, error);
        },
        data: (order) {
          if (order == null) {
            return _buildLoading();
          }
          return _buildTrackingContent(context, order);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Loading state
  // ---------------------------------------------------------------------------

  Widget _buildLoading() {
    return Center(
      child: Semantics(
        label: 'Loading order tracking information',
        child: const CircularProgressIndicator(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Error state
  // ---------------------------------------------------------------------------

  Widget _buildError(BuildContext context, Object error) {
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
              'Unable to load order tracking',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Retries watching the order after an error.
  void _onRetry() {
    ref
        .read(deliveryTrackingNotifierProvider.notifier)
        .watchOrder(widget.orderId);
  }

  // ---------------------------------------------------------------------------
  // Reconnecting state (network loss with last known data)
  // ---------------------------------------------------------------------------

  /// Shows the last known order tracking content with a non-blocking
  /// "Reconnecting..." banner at the top.
  ///
  /// Displayed when the Firestore stream errors but we already have data.
  /// Satisfies Design doc Error Handling: "Network loss during tracking →
  /// Show last known status + 'Reconnecting...' indicator".
  Widget _buildReconnectingContent(BuildContext context, Order lastKnownOrder) {
    return Column(
      children: [
        // ── Reconnecting banner ─────────────────────────────────────────
        Material(
          color: Theme.of(context).colorScheme.errorContainer,
          child: Semantics(
            label: 'Reconnecting to server',
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color:
                          Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Reconnecting...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onErrorContainer,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // ── Last known tracking content ─────────────────────────────────
        Expanded(
          child: _buildTrackingContent(context, lastKnownOrder),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tracking content
  // ---------------------------------------------------------------------------

  Widget _buildTrackingContent(BuildContext context, Order order) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Order ID header ──────────────────────────────────────────────
          Semantics(
            label: 'Order ${order.id}',
            child: Text(
              'Order #${order.id}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Status timeline (Req 2 AC3) ─────────────────────────────────
          DeliveryStatusTimeline(currentStatus: order.status),

          const SizedBox(height: 24),

          // ── ETA card (Req 2 AC4) ────────────────────────────────────────
          // Shown only when status is outForDelivery
          if (order.status == DeliveryStatus.outForDelivery)
            ETACard(etaMinutes: order.etaMinutes),

          // ── Delivery confirmation + Rate Order (Req 2 AC5) ──────────────
          if (order.status == DeliveryStatus.delivered)
            _buildDeliveredSection(context, order),

          // ── Failure info ────────────────────────────────────────────────
          if (order.status == DeliveryStatus.failed)
            _buildFailedSection(context, order),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Delivered section (Req 2 AC5)
  // ---------------------------------------------------------------------------

  Widget _buildDeliveredSection(BuildContext context, Order order) {
    return Semantics(
      label: 'Order delivered successfully',
      child: Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.check_circle,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'Order Delivered!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your order has been delivered successfully. '
                'We hope you enjoy your meal!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _onRateOrder(order.id),
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Rate Order'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Navigates to the rating screen for the given order.
  void _onRateOrder(String orderId) {
    // Navigation to RatingScreen will be wired when that screen is implemented.
    // For now, this is a placeholder action.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rating screen coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Failed section
  // ---------------------------------------------------------------------------

  Widget _buildFailedSection(BuildContext context, Order order) {
    return Semantics(
      label: 'Delivery failed',
      child: Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.cancel_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                'Delivery Failed',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
              ),
              if (order.failureReason != null) ...[
                const SizedBox(height: 8),
                Text(
                  order.failureReason!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onErrorContainer,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'We will contact you shortly to resolve this issue.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


