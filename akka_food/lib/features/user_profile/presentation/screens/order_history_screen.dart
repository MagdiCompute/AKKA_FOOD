import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../domain/entities/order_summary.dart';
import '../notifiers/order_history_notifier.dart';

/// Screen that displays the authenticated user's paginated order history.
///
/// Features:
/// - Infinite scroll: detects when the user reaches the bottom of the list
///   and calls [OrderHistoryNotifier.loadNextPage].
/// - Each order tile shows: order date, color-coded status badge, total
///   amount in XOF, and item count.
/// - Loading state: [CircularProgressIndicator].
/// - Empty state: "No orders yet" message (Requirement 5.4).
/// - Connectivity banner when the notifier has an error but stale data is
///   available (Requirement 5.5).
/// - Tapping an order navigates to [AppRoutes.orderDetail] (Requirement 5.3).
///
/// Satisfies Requirements 5.1–5.5.
class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() =>
      _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Triggers [loadNextPage] when the user scrolls within 200 px of the
  /// bottom of the list.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    if (currentScroll >= maxScroll - 200) {
      final notifier =
          ref.read(orderHistoryNotifierProvider.notifier);
      if (notifier.hasMore) {
        notifier.loadNextPage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(orderHistoryNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des commandes'),
        centerTitle: true,
      ),
      body: ordersAsync.when(
        // Initial full-screen loading (no previous data).
        loading: () => const Center(child: CircularProgressIndicator()),
        // Hard error with no cached data.
        error: (error, _) => _ErrorView(
          message: error.toString(),
          onRetry: () =>
              ref.read(orderHistoryNotifierProvider.notifier).refresh(),
        ),
        data: (orders) => _OrderList(
          orders: orders,
          scrollController: _scrollController,
          isLoadingMore: ordersAsync.isLoading,
          hasError: ordersAsync.hasError,
          hasMore:
              ref.read(orderHistoryNotifierProvider.notifier).hasMore,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _OrderList
// ---------------------------------------------------------------------------

class _OrderList extends ConsumerWidget {
  const _OrderList({
    required this.orders,
    required this.scrollController,
    required this.isLoadingMore,
    required this.hasError,
    required this.hasMore,
  });

  final List<OrderSummary> orders;
  final ScrollController scrollController;
  final bool isLoadingMore;
  final bool hasError;
  final bool hasMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (orders.isEmpty) {
      return const _EmptyState();
    }

    return Column(
      children: [
        // Connectivity banner — shown when we have stale data but the last
        // fetch failed (Requirement 5.5).
        if (hasError) const _ConnectivityBanner(),

        Expanded(
          child: ListView.separated(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: orders.length + (hasMore ? 1 : 0),
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              // Footer: loading indicator or end-of-list sentinel.
              if (index == orders.length) {
                return isLoadingMore
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : const SizedBox.shrink();
              }

              final order = orders[index];
              return _OrderTile(
                order: order,
                onTap: () => context.push(
                  AppRoutes.orderDetail
                      .replaceFirst(':orderId', order.orderId),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _OrderTile
// ---------------------------------------------------------------------------

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.onTap});

  final OrderSummary order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr =
        DateFormat('dd MMM yyyy, HH:mm').format(order.orderDate);
    final itemCount = order.items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    final amountStr =
        NumberFormat('#,##0', 'fr_FR').format(order.totalAmount);

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      onTap: onTap,
      title: Row(
        children: [
          Expanded(
            child: Text(
              dateStr,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _StatusBadge(status: order.status),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Text(
              '$amountStr XOF',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$itemCount ${itemCount == 1 ? 'article' : 'articles'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurfaceVariant,
      ),
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
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
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
// _ConnectivityBanner
// ---------------------------------------------------------------------------

class _ConnectivityBanner extends StatelessWidget {
  const _ConnectivityBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.orange.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.wifi_off, size: 18, color: Colors.orange.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Vous êtes hors ligne. Historique des commandes en cache affiché.",
              style: TextStyle(
                color: Colors.orange.shade900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _EmptyState
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune commande pour le moment',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Votre historique de commandes apparaîtra ici une fois votre première commande passée.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
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
              'Échec du chargement de l\'historique des commandes',
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
