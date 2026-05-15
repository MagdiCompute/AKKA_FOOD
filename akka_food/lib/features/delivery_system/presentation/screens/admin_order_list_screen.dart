import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/delivery_status.dart';
import '../../domain/entities/order.dart';
import '../notifiers/delivery_tracking_notifier.dart';
import 'admin_order_detail_screen.dart';

part 'admin_order_list_screen.g.dart';

// ---------------------------------------------------------------------------
// Active Orders Provider
// ---------------------------------------------------------------------------

/// Provides a real-time stream of active (non-terminal) delivery orders.
///
/// Uses [IDeliveryRepository.getActiveOrders()] which returns orders whose
/// status is not `delivered` or `failed`, sorted by `createdAt` ascending.
///
/// Satisfies Requirement 4 AC2.
@riverpod
Stream<List<Order>> activeOrders(Ref ref) {
  final repository = ref.watch(deliveryRepositoryProvider);
  return repository.getActiveOrders();
}

// ---------------------------------------------------------------------------
// AdminOrderListScreen
// ---------------------------------------------------------------------------

/// Admin screen that displays all active delivery orders with real-time
/// updates from Firestore.
///
/// Orders are sorted by creation time ascending (oldest first).
/// Each list item shows: order ID, status badge, and creation time.
/// Tapping an order navigates to the admin order detail screen.
///
/// Handles loading, error, and empty states.
///
/// Satisfies Requirement 4 AC2.
class AdminOrderListScreen extends ConsumerWidget {
  const AdminOrderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(activeOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commandes actives'),
      ),
      body: ordersAsync.when(
        loading: () => _buildLoading(context),
        error: (error, _) => _buildError(context, error),
        data: (orders) {
          if (orders.isEmpty) {
            return _buildEmpty(context);
          }
          // Sort by createdAt ascending (oldest first) as a safety measure,
          // even though the Firestore query already orders them.
          final sortedOrders = List<Order>.from(orders)
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return _buildOrderList(context, sortedOrders);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Loading state
  // ---------------------------------------------------------------------------

  Widget _buildLoading(BuildContext context) {
    return Center(
      child: Semantics(
        label: 'Chargement des commandes',
        child: const CircularProgressIndicator(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Error state
  // ---------------------------------------------------------------------------

  Widget _buildError(BuildContext context, Object error) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Impossible de charger les commandes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Veuillez vérifier votre connexion et réessayer.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty state
  // ---------------------------------------------------------------------------

  Widget _buildEmpty(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune commande active',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Les commandes actives apparaîtront ici en temps réel.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.outline,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Order list
  // ---------------------------------------------------------------------------

  Widget _buildOrderList(BuildContext context, List<Order> orders) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _ActiveOrderTile(
          key: ValueKey(order.id),
          order: order,
          onTap: () => _navigateToDetail(context, order.id),
        );
      },
    );
  }

  /// Navigates to the admin order detail screen.
  void _navigateToDetail(BuildContext context, String orderId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminOrderDetailScreen(orderId: orderId),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ActiveOrderTile
// ---------------------------------------------------------------------------

/// A single list tile representing an active delivery order.
///
/// Displays:
/// - Order ID (truncated for readability)
/// - Status badge with color coding
/// - Creation time formatted as date and time
///
/// Accessible via [Semantics] with a descriptive label.
class _ActiveOrderTile extends StatelessWidget {
  const _ActiveOrderTile({
    super.key,
    required this.order,
    required this.onTap,
  });

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: 'Commande ${order.id}, statut ${order.status.label}, '
          'créée le ${_formatDateTime(order.createdAt)}',
      button: true,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // ── Order info ──────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order ID
                      Text(
                        'Commande #${_truncateId(order.id)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Creation time
                      Text(
                        _formatDateTime(order.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // ── Status badge ────────────────────────────────────────
                _StatusBadge(status: order.status),
                const SizedBox(width: 8),
                // ── Chevron ─────────────────────────────────────────────
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Truncates long order IDs for display (show first 8 characters).
  String _truncateId(String id) {
    if (id.length <= 8) return id;
    return '${id.substring(0, 8)}…';
  }

  /// Formats a [DateTime] as "dd/MM/yyyy HH:mm".
  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

// ---------------------------------------------------------------------------
// _StatusBadge
// ---------------------------------------------------------------------------

/// A colored chip displaying the delivery status label.
///
/// Color coding:
/// - pending: orange
/// - confirmed: blue
/// - preparing: purple
/// - outForDelivery: teal
/// - delivered/failed: should not appear (filtered out), but handled gracefully
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final DeliveryStatus status;

  @override
  Widget build(BuildContext context) {
    final (backgroundColor, foregroundColor) = _statusColors(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  (Color, Color) _statusColors(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (status) {
      case DeliveryStatus.pending:
        return (Colors.orange.shade100, Colors.orange.shade900);
      case DeliveryStatus.confirmed:
        return (Colors.blue.shade100, Colors.blue.shade900);
      case DeliveryStatus.preparing:
        return (Colors.purple.shade100, Colors.purple.shade900);
      case DeliveryStatus.readyForPickup:
        return (Colors.indigo.shade100, Colors.indigo.shade900);
      case DeliveryStatus.outForDelivery:
        return (Colors.teal.shade100, Colors.teal.shade900);
      case DeliveryStatus.delivered:
        return (Colors.green.shade100, Colors.green.shade900);
      case DeliveryStatus.failed:
        return (colorScheme.errorContainer, colorScheme.onErrorContainer);
    }
  }
}
