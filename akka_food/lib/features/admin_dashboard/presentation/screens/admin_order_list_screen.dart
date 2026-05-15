import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/admin_order_view.dart';
import '../notifiers/admin_order_notifier.dart';
import '../widgets/order_list_tile.dart';

/// Displays all active orders with real-time updates, search, filter controls,
/// and navigation to the order detail screen.
///
/// Satisfies Requirements 4.1, 4.4, and 5.5.
class AdminOrderListScreen extends ConsumerStatefulWidget {
  const AdminOrderListScreen({super.key});

  @override
  ConsumerState<AdminOrderListScreen> createState() =>
      _AdminOrderListScreenState();
}

class _AdminOrderListScreenState extends ConsumerState<AdminOrderListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(adminOrderNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commandes'),
        actions: [
          // Clear filters button — only shown when a filter or search is active.
          orderState.whenOrNull(
                data: (state) {
                  final hasFilter = state.selectedStatus != null ||
                      state.dateRange != null ||
                      state.selectedDeliveryOption != null ||
                      state.searchQuery.isNotEmpty;
                  if (!hasFilter) return null;
                  return IconButton(
                    icon: const Icon(Icons.filter_alt_off_outlined),
                    tooltip: 'Effacer les filtres',
                    onPressed: () {
                      _searchController.clear();
                      ref
                          .read(adminOrderNotifierProvider.notifier)
                          .clearFilters();
                    },
                  );
                },
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par ID ou nom du client…',
                prefixIcon: const Icon(Icons.search_outlined),
                suffixIcon: orderState.whenOrNull(
                  data: (state) => state.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'Effacer la recherche',
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(adminOrderNotifierProvider.notifier)
                                .setSearchQuery('');
                          },
                        )
                      : null,
                ),
                border: const OutlineInputBorder(),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (value) => ref
                  .read(adminOrderNotifierProvider.notifier)
                  .setSearchQuery(value),
            ),
          ),

          // ── Filter bar ─────────────────────────────────────────────────
          orderState.when(
            data: (state) => _OrderFilterBar(
              selectedStatus: state.selectedStatus,
              dateRange: state.dateRange,
              selectedDeliveryOption: state.selectedDeliveryOption,
              onStatusSelected: (status) => ref
                  .read(adminOrderNotifierProvider.notifier)
                  .setStatusFilter(status),
              onDateRangePicked: (range) => ref
                  .read(adminOrderNotifierProvider.notifier)
                  .setDateRange(range),
              onDeliveryOptionSelected: (option) => ref
                  .read(adminOrderNotifierProvider.notifier)
                  .setDeliveryOptionFilter(option),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // ── Order list ─────────────────────────────────────────────────
          Expanded(
            child: orderState.when(
              data: (state) {
                final orders = state.filteredOrders;

                if (orders.isEmpty) {
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
                          state.allOrders.isEmpty
                              ? 'Aucune commande pour le moment.'
                              : 'Aucune commande ne correspond aux filtres.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return OrderListTile(
                      key: ValueKey(order.orderId),
                      order: order,
                      onTap: () => context.push(
                        '/admin/orders/${order.orderId}',
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Échec du chargement des commandes.\n$error',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter bar
// ---------------------------------------------------------------------------

/// Horizontal scrollable filter bar with status chips, date range picker,
/// and delivery option filter.
///
/// Satisfies Requirement 4.4.
class _OrderFilterBar extends StatelessWidget {
  const _OrderFilterBar({
    required this.selectedStatus,
    required this.dateRange,
    required this.selectedDeliveryOption,
    required this.onStatusSelected,
    required this.onDateRangePicked,
    required this.onDeliveryOptionSelected,
  });

  final DeliveryStatus? selectedStatus;
  final DateTimeRange? dateRange;
  final DeliveryOption? selectedDeliveryOption;
  final ValueChanged<DeliveryStatus?> onStatusSelected;
  final ValueChanged<DateTimeRange?> onDateRangePicked;
  final ValueChanged<DeliveryOption?> onDeliveryOptionSelected;

  /// Statuses that can be filtered in the admin order list.
  static const _filterableStatuses = [
    DeliveryStatus.pending,
    DeliveryStatus.confirmed,
    DeliveryStatus.preparing,
    DeliveryStatus.readyForPickup,
    DeliveryStatus.outForDelivery,
    DeliveryStatus.delivered,
    DeliveryStatus.cancelled,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          // ── Status chips ──────────────────────────────────────────────
          ..._filterableStatuses.map(
            (status) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(status.label),
                selected: selectedStatus == status,
                onSelected: (selected) =>
                    onStatusSelected(selected ? status : null),
              ),
            ),
          ),

          // ── Date range picker button ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _DateRangeButton(
              dateRange: dateRange,
              onPicked: onDateRangePicked,
            ),
          ),

          // ── Delivery option chips ─────────────────────────────────────
          ...DeliveryOption.values.map(
            (option) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: Icon(
                  option == DeliveryOption.delivery
                      ? Icons.delivery_dining_outlined
                      : Icons.storefront_outlined,
                  size: 16,
                ),
                label: Text(option.label),
                selected: selectedDeliveryOption == option,
                onSelected: (selected) =>
                    onDeliveryOptionSelected(selected ? option : null),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Date range button
// ---------------------------------------------------------------------------

/// A button that opens a date range picker and displays the selected range.
class _DateRangeButton extends StatelessWidget {
  const _DateRangeButton({
    required this.dateRange,
    required this.onPicked,
  });

  final DateTimeRange? dateRange;
  final ValueChanged<DateTimeRange?> onPicked;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasRange = dateRange != null;

    return ActionChip(
      avatar: Icon(
        Icons.date_range_outlined,
        size: 16,
        color: hasRange ? colorScheme.onSecondaryContainer : null,
      ),
      label: Text(
        hasRange ? _formatRange(dateRange!) : 'Date',        style: hasRange
            ? TextStyle(color: colorScheme.onSecondaryContainer)
            : null,
      ),
      backgroundColor:
          hasRange ? colorScheme.secondaryContainer : null,
      onPressed: () async {
        final now = DateTime.now();
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(now.year - 1),
          lastDate: now,
          initialDateRange: dateRange,
        );
        if (picked != null) {
          onPicked(picked);
        } else if (hasRange) {
          // User cancelled — keep existing range; to clear, use clear button.
        }
      },
    );
  }

  String _formatRange(DateTimeRange range) {
    final start = _fmt(range.start);
    final end = _fmt(range.end);
    return '$start – $end';
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
}
