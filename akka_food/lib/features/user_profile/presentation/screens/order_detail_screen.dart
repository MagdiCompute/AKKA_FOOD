import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/order_summary.dart';
import '../notifiers/order_history_notifier.dart';

part 'order_detail_screen.g.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Fetches the full [OrderSummary] for [orderId] from the repository.
///
/// Uses `.family` so each orderId gets its own cached provider instance.
/// Always fetches from Firestore — individual orders are not cached
/// (see [OrderRepository.getOrderDetail]).
///
/// Satisfies Requirement 5.3.
@riverpod
Future<OrderSummary> orderDetail(Ref ref, String orderId) async {
  final repository = await ref.watch(orderRepositoryProvider.future);
  return repository.getOrderDetail(orderId);
}

// ---------------------------------------------------------------------------
// OrderDetailScreen
// ---------------------------------------------------------------------------

/// Screen that displays the full details of a single order.
///
/// Features:
/// - Order ID (truncated to first 8 characters for readability).
/// - Order date formatted as "dd MMM yyyy, HH:mm".
/// - Color-coded status badge.
/// - Delivery address (if available).
/// - Payment method.
/// - List of items with name, quantity, unit price, and subtotal per item.
/// - Total amount in XOF.
/// - Loading state: [CircularProgressIndicator].
/// - Error state: error message with retry button.
///
/// Satisfies Requirement 5.3.
class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  /// The Firestore document ID of the order to display.
  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Commande #${_truncateId(widget.orderId)}',
        ),
        centerTitle: true,
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: error.toString(),
          onRetry: () =>
              ref.invalidate(orderDetailProvider(widget.orderId)),
        ),
        data: (order) => _OrderDetailBody(order: order),
      ),
    );
  }

  /// Returns the first 8 characters of [id] in uppercase.
  static String _truncateId(String id) {
    if (id.length <= 8) return id.toUpperCase();
    return id.substring(0, 8).toUpperCase();
  }
}

// ---------------------------------------------------------------------------
// _OrderDetailBody
// ---------------------------------------------------------------------------

class _OrderDetailBody extends StatelessWidget {
  const _OrderDetailBody({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr =
        DateFormat('dd MMM yyyy, HH:mm', 'fr_FR').format(order.orderDate);
    final totalStr =
        NumberFormat('#,##0', 'fr_FR').format(order.totalAmount);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Order header card ──────────────────────────────────────────
        _SectionCard(
          children: [
            _DetailRow(
              label: 'N° de commande',
              value: order.orderId.length > 8
                  ? '${order.orderId.substring(0, 8).toUpperCase()}…'
                  : order.orderId.toUpperCase(),
            ),
            const SizedBox(height: 8),
            _DetailRow(label: 'Date', value: dateStr),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Statut',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                _StatusBadge(status: order.status),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── Delivery & payment ─────────────────────────────────────────
        _SectionCard(
          children: [
            if (order.deliveryAddress != null &&
                order.deliveryAddress!.isNotEmpty) ...[
              _DetailRow(
                label: 'Adresse de livraison',
                value: order.deliveryAddress!,
              ),
              const SizedBox(height: 8),
            ],
            _DetailRow(
              label: 'Mode de paiement',
              value: order.paymentMethod,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── Items ──────────────────────────────────────────────────────
        Text(
          'Articles',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _SectionCard(
          children: [
            ...order.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  if (index > 0) const Divider(height: 16),
                  _OrderItemRow(item: item),
                ],
              );
            }),
          ],
        ),

        const SizedBox(height: 16),

        // ── Total ──────────────────────────────────────────────────────
        _SectionCard(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$totalStr XOF',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ── Track order button ─────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => context.push('/orders/${order.orderId}/tracking'),
            icon: const Icon(Icons.local_shipping_outlined),
            label: const Text('Suivi de commande'),
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _OrderItemRow
// ---------------------------------------------------------------------------

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unitPriceStr =
        NumberFormat('#,##0', 'fr_FR').format(item.unitPrice);
    final subtotal = item.quantity * item.unitPrice;
    final subtotalStr = NumberFormat('#,##0', 'fr_FR').format(subtotal);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quantity badge
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${item.quantity}×',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Name + unit price
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$unitPriceStr XOF / unité',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        // Subtotal
        Text(
          '$subtotalStr XOF',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _StatusBadge
// ---------------------------------------------------------------------------

/// Color-coded badge that reflects the order status.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _statusStyle(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static (String, Color) _statusStyle(String status) {
    return switch (status.toLowerCase()) {
      'pending' => ('En attente', Colors.orange),
      'confirmed' => ('Confirmée', Colors.blue),
      'preparing' => ('En préparation', Colors.purple),
      'ready_for_pickup' => ('Prêt à récupérer', Colors.indigo),
      'out_for_delivery' => ('En livraison', Colors.teal),
      'delivered' => ('Livrée', Colors.green),
      'cancelled' => ('Annulée', Colors.red),
      _ => (status, Colors.grey),
    };
  }
}

// ---------------------------------------------------------------------------
// _SectionCard
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _DetailRow
// ---------------------------------------------------------------------------

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _ErrorView
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Échec du chargement des détails de la commande',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
